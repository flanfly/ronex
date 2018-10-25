defmodule LWW do
  def reduce(_, []), do: []
  def reduce(state, update) do
    [head | _] = state
    %Op{ event: latest } = Enum.at(update, -1)
    spec = %Op{ head | event: latest, location: UUID.zero(), term: :header }
    body = Enum.filter(state ++ update, fn %Op{ term: term } ->
      term != :header and term != :query
    end)
    |> Enum.sort(fn a,b ->
      if a.location == b.location do
        a.event > b.event
      else
        a.location < b.location
      end
    end)
    |> Enum.chunk_by(fn %Op{ location: loc } -> loc end)
    |> Enum.map(fn [op | _] -> %Op{ op | term: :reduced } end)

    [spec | body]
  end

  def map([]), do: %{}
  def map(state) do
    Enum.reduce(state, %{}, fn
      %Op{ term: :header }, acc -> acc
      %Op{ atoms: [] }, acc -> acc
      %Op{ location: loc, atoms: [val] }, acc when is_float(val) ->
        Map.put(acc, loc, Float.round(val, 5))
      %Op{ location: loc, atoms: [val] }, acc ->
        Map.put(acc, loc, val)
    end)
  end
end

