defmodule RGA do
  def reduce(state, update) do
    state = Frame.split(state)
    update = Frame.split(update)
    frames = state ++ update
    {rms, todo} =
      Enum.split_with(frames, fn
        [%Op{ term: term, atoms: [] } | _] when term != :header and term != :query -> true
        [%Op{ term: :header, location: %UUID{ hi: hi, scheme: :event } } | _] ->
          hi != 0
        _ -> false
      end)

    rms = Enum.concat(rms)
      |> Enum.filter(fn %Op{ term: term } ->
        term != :query and term != :header
      end)
      |> Enum.map(fn
        %Op{ event: ev, location: loc } -> {loc,ev}
        _ -> :nil
      end)
      |> Enum.filter(fn x -> x != :nil end)
      |> Enum.sort(fn {a,_},{b,_} -> UUID.is_less?(a,b) end)
      |> Enum.chunk_by(fn {ev,_} -> ev end)
      |> Enum.map(fn chunk ->
        Enum.sort(chunk, fn {_,a},{_,b} -> UUID.is_less?(a,b) end) |> hd
      end)
      |> Map.new
    [[%Op{ object: obj, type: ty } | _] | _] = state
    event = Enum.reduce(frames, UUID.zero(), fn [x | _],acc ->
      if UUID.is_less?(acc, x.event) do x.event else acc end
    end)
    # order incoming frames by location
    todo =
      Enum.sort(todo, fn
        [%Op{ location: loc1 } | _],[%Op{ location: loc2 } | _] ->
          UUID.is_less?(loc1, loc2)
      end)
    IO.inspect todo, label: "todo"
    taps =
      Enum.reverse(0..(length(todo)) - 1)
      |> Enum.map(fn idx ->
        [%Op{ location: loc } | _] = Enum.at(todo, idx)
        IO.inspect {idx,loc}, label: "tap"
          {loc, idx}
        end)
      |> Map.new

    IO.inspect rms, label: "rms"
    IO.inspect taps, label: "taps"
    {state, _} = subtree([], [], todo, ty, obj, event, rms, taps)
    # emit rm frame
    state
  end

  defp normalize_frame(frame) do
    frame |> Enum.filter(fn %Op{ term: term } ->
      term != :query and term != :header
    end)
    |> Enum.map(fn
      op = %Op{ term: :raw } ->
        %Op{ op | location: UUID.zero(), term: :reduced }
      op -> op
    end)
    |> Enum.sort(fn
      %Op{ location: loc1, event: ev1 },%Op{ location: loc2, event: ev2 } -> cond do
        loc1 == loc2 -> UUID.is_less?(ev1, ev2)
        true -> UUID.is_less?(loc2, loc1)
      end
    end)
  end

  defp subtree(state, [], frames, ty, obj, ev, rms, taps) do
    case Enum.find_index(frames, &(&1 != [])) do
      nil -> {state, rms}
      idx ->
        [%Op{ location: ref } |_] = Enum.at(frames, idx)
        {todo, frames} = Enum.reduce(frames, {[], []}, fn
          [], {todo, frames} -> {todo, frames ++ [[]]}
          [%Op{ location: loc } |_] = frm, {todo, frames} ->
            if loc == ref do
              {todo ++ frm, frames ++ [[]]}
            else
              {todo, frames ++ [frm]}
            end
        end)

        IO.inspect ref, label: "init ref"
        IO.inspect {todo,frames}, label: "init. subtree"

        # new state frame
        todo = normalize_frame(todo)
        hdr = %Op{
          type: ty, event: ev,
          object: obj, location: ref,
          atoms: [], term: :header
        }

        IO.inspect todo, label: "new chunk"
        subtree(state ++ [[hdr]], todo, frames, ty, obj, ev, rms, taps)
    end
  end
  defp subtree(state, todo, frames, ty, obj, ev, rms, taps) do
    IO.inspect todo, label: "subtree"
    [%Op{ event: car_ev, location: car_loc } = car | cdr] = todo
    {car, rms} = case Map.get(rms, car_ev) do
      nil -> {car, rms}
      rm ->
        if UUID.is_less?(car_loc, rm) do
          rms = Map.delete(rms, car_ev)
          {%Op{ car | location: rm }, rms}
        else
          {car, rms}
        end
    end

    %Op{ event: car_ev } = car
    active = List.last(state)
    state = List.replace_at(state, length(state) - 1, active ++ [car])
    {tapped, taps, frames} = case Map.pop(taps, car_ev) do
      {nil, taps} ->
        {[], taps, frames}
      {idx, taps} ->
        case Enum.at(frames, idx) do
          [] ->
            {[], taps, frames}
          tapped ->
            frames = List.replace_at(frames, idx, [])
            {tapped, taps, frames}
        end
    end

    IO.inspect cdr, label: "before"
    cdr = normalize_frame(cdr ++ tapped)
    cdr = Enum.drop_while(cdr, fn %Op{ event: e } -> e == car_ev end)
    IO.inspect cdr, label: "after"
    subtree(state, cdr, frames, ty, obj, ev, rms, taps)
  end

  def map(state) do
    state = Enum.sort(state, fn a,b ->
      cond do
        # sort deletions before insertions
        a.location == b.location and a.atoms == [] -> true
        a.location == b.location and b.atoms == [] -> false

        # sort causing ops before caused
        a.event == b.location -> true
        b.event == a.location -> false

        # otherwise, sort by (ev, loc)
        a.event == b.event -> UUID.is_less?(a.location, b.location)
        true -> UUID.is_less?(a.event, b.event)
      end
    end)

    state
      |> Enum.chunk_every(2, 1)
      |> Enum.map(fn [a | [b | []]] ->
        case {a,b} do
          {%Op{ event: ev, atoms: [_] }, %Op{ location: loc, atoms: [] }} when ev == loc -> :nil
          {%Op{ atoms: [char] }, _} -> char
          _ -> :nil
        end
        [%Op{ atoms: [char] } | []] -> char
        [%Op{ atoms: [] } | []] -> :nil
      end)
      |> Enum.filter(fn x -> x != :nil end)
      |> Enum.reduce("", fn x, acc -> acc <> x end)
  end
end
