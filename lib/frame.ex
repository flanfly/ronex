defmodule Frame do
  defstruct type: :nil, ops: :nil

  def from_text(str) do
    %Frame{ type: :txt, ops: str }
  end

  def from_binary(str) do
    %Frame{ type: :bin, ops: str }
  end

  def stream(%UUID{ }) do
    :nil
  end

  def decode_op("", _) do
    :ok
  end

  def decode_op(txt, {prev_ty, prev_obj, prev_ev, prev_loc}) do
    trimmed = String.trim_leading(txt)

    # types
    {my_ty, trimmed} = case trimmed do
      "*" <> cdr -> uuid(cdr, prev_ty)
      "#" <> _ -> {prev_ty, trimmed}
      "@" <> _ -> {prev_ty, trimmed}
      ":" <> _ -> {prev_ty, trimmed}
      "'" <> _ -> {prev_ty, trimmed}
      "!" <> _ -> {prev_ty, trimmed}
      "^" <> _ -> {prev_ty, trimmed}
      "=" <> _ -> {prev_ty, trimmed}
      ">" <> _ -> {prev_ty, trimmed}
      "," <> _ -> {prev_ty, trimmed}
      ";" <> _ -> {prev_ty, trimmed}
      "!" <> _ -> {prev_ty, trimmed}
      "?" <> _ -> {prev_ty, trimmed}
      "" -> {prev_ty, trimmed}
        _ -> raise "cannot decode type"
    end

    # object
    {my_obj, trimmed} = case trimmed do
      "#" <> cdr -> uuid(cdr, prev_obj)
      "@" <> _ -> {prev_obj, trimmed}
      ":" <> _ -> {prev_obj, trimmed}
      "'" <> _ -> {prev_obj, trimmed}
      "!" <> _ -> {prev_obj, trimmed}
      "^" <> _ -> {prev_obj, trimmed}
      "=" <> _ -> {prev_obj, trimmed}
      ">" <> _ -> {prev_obj, trimmed}
      "," <> _ -> {prev_obj, trimmed}
      ";" <> _ -> {prev_obj, trimmed}
      "!" <> _ -> {prev_obj, trimmed}
      "?" <> _ -> {prev_obj, trimmed}
      "" -> {prev_obj, trimmed}
      _ -> raise "cannot decode object"
    end

    # event
    {my_ev, trimmed} = case trimmed do
      "@" <> cdr -> uuid(cdr, prev_ev)
      ":" <> _ -> {prev_ev, trimmed}
      "'" <> _ -> {prev_ev, trimmed}
      "!" <> _ -> {prev_ev, trimmed}
      "^" <> _ -> {prev_ev, trimmed}
      "=" <> _ -> {prev_ev, trimmed}
      ">" <> _ -> {prev_ev, trimmed}
      "," <> _ -> {prev_ev, trimmed}
      ";" <> _ -> {prev_ev, trimmed}
      "!" <> _ -> {prev_ev, trimmed}
      "?" <> _ -> {prev_ev, trimmed}
      "" -> {prev_ev, trimmed}
        _ -> raise "cannot decode event"
    end

    # location
    {my_loc, trimmed} = case trimmed do
      ":" <> cdr -> uuid(cdr, prev_loc)
      "'" <> _ -> {prev_loc, trimmed}
      "!" <> _ -> {prev_loc, trimmed}
      "^" <> _ -> {prev_loc, trimmed}
      "=" <> _ -> {prev_loc, trimmed}
      ">" <> _ -> {prev_loc, trimmed}
      "," <> _ -> {prev_loc, trimmed}
      ";" <> _ -> {prev_loc, trimmed}
      "!" <> _ -> {prev_loc, trimmed}
      "?" <> _ -> {prev_loc, trimmed}
      "" -> {prev_loc, trimmed}
      _ -> raise "cannot decode location"
    end

    # atoms
    {my_atoms, trimmed} = atoms(trimmed, my_loc)

    op = {my_ty, my_obj, my_ev, my_loc}
    IO.inspect op
    IO.inspect my_atoms

    decode_op(trimmed, op)
  end

  defp atoms(txt, prev_uuid), do: atoms(txt, prev_uuid, [])
  defp atoms("", _, prev), do: {prev, ""}
  defp atoms(txt, prev_uuid, prev) do
    txt = String.trim_leading(txt)
    car = String.first(txt) |> :binary.first
    cdr = String.slice(txt, 1..-1)

    case car do
      ?! -> atoms(cdr, [:nil | prev])
      ?> ->
        {uu, cdr} = uuid(String.trim_leading(cdr), prev_uuid)
        atoms(cdr, prev_uuid, [uu | prev])

      ?= ->
        {car, cdr} = Enum.split_while(
          String.trim_leading(cdr),
          fn c -> :binary.first(c) in ?0..?9 end)
        atoms(cdr, prev_uuid, [String.to_integer(car) | prev])

      ?^ -> raise :nil
      ?' ->
        {str, cdr} = string(cdr, {:def, ""})
        atoms(cdr, prev_uuid, [str | prev])

      _ -> {prev, txt}
    end
  end

  defp string(txt, {state, str}) do
    car = String.first(txt) |> :binary.first
    cdr = String.slice(txt, 1..-1)

    case car do
      ?' when state == :def ->
        {str, cdr}
      ?' when state == :esc ->
        string(cdr, {:def, str <> "'"})
      ?\\ when state == :def ->
        string(cdr, {:esc, str})
      ?\\ when state == :esc ->
        string(cdr, {:def, str <> "\\"})
      _ when state == :def ->
        string(cdr, {:def, str <> String.first(txt)})
        # XXX: more escape seqs
    end
  end

  defp uuid(txt, prev), do: uuid(txt, prev, {0, 0, 0, 0, :name})
  defp uuid(txt, prev, {hi, hi_bits, lo, lo_bits, sch}) do
    use Bitwise

    txt = String.trim_leading(txt)
    car = String.first(txt) |> :binary.first
    cdr = String.slice(txt, 1..-1)
    is_uuid_char = car in ?0..?9 or car in ?a..?z
      or car in ?A..?Z or car == ?~ or car == ?_

    case car do
      _ when is_uuid_char ->
        val = case car do
          car when car in ?0..?9 -> car - ?0
          car when car in ?A..?Z -> car - ?A + 10
          ?_ -> 36
          car when car in ?a..?z -> car - ?a + 37
          ?~ -> 63
        end

        state = case hi_bits do
          10 ->
            i = 10 - lo_bits
            { hi, hi_bits,
              lo ||| (val <<< (6 * i)), lo_bits + 1,
              sch }
          x when x in 0..9 ->
            i = 10 - hi_bits
            { hi ||| (val <<< (6 * i)), hi_bits + 1,
              lo, lo_bits,
              sch }
        end

        uuid(cdr, prev, state)

      ?( when hi_bits == 0 -> uuid(cdr, prev, {prev.hi >>> 6, 4, 0, 0, sch})
      ?( -> raise "( prefix inside uuid"

      ?[ when hi_bits == 0 -> uuid(cdr, prev, {prev.hi >>> 5, 5, 0, 0, sch})
      ?[ -> raise "[ prefix inside uuid"

      ?{ when hi_bits == 0 -> uuid(cdr, prev, {prev.hi >>> 4, 6, 0, 0, sch})
      ?{ -> raise "{ prefix inside uuid"

      ?} when hi_bits == 0 -> uuid(cdr, prev, {prev.hi >>> 3, 7, 0, 0, sch})
      ?} -> raise "} prefix inside uuid"

      ?] when hi_bits == 0 -> uuid(cdr, prev, {prev.hi >>> 2, 8, 0, 0, sch})
      ?] -> raise "] prefix inside uuid"

      ?) when hi_bits == 0 -> uuid(cdr, prev, {prev.hi >>> 1, 9, 0, 0, sch})
      ?) -> raise ") prefix inside uuid"

      ?` -> raise :nil

      ?+ when lo_bits == 0 -> uuid(cdr, prev, {hi, 10, 0, 0, :derived})
      ?% when lo_bits == 0 -> uuid(cdr, prev, {hi, 10, 0, 0, :hash})
      ?- when lo_bits == 0 -> uuid(cdr, prev, {hi, 10, 0, 0, :event})
      ?$ when lo_bits == 0 -> uuid(cdr, prev, {hi, 10, 0, 0, :name})

      _ ->
      cond do
        hi == 0 and lo == 0 ->
          {%UUID{ hi: 0, lo: 0, scheme: :null }, txt}
        true ->
          {%UUID{ hi: hi, lo: lo, scheme: sch }, txt}
      end
    end
  end
end
