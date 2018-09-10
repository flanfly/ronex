defmodule LWW do
  def reduce([], []), do: []
  def reduce(frame) do
    [head | _] = frame
    latest = Enum.at(frame, -1).event
    spec = %Op{ head | event: latest, location: UUID.zero(), term: :header }

    [spec |
      frame
      |> Enum.filter(fn %Op{ term: term } ->
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
      |> Enum.map(fn [op | _] -> op end)
    ]
  end

  def map([]), do: %{}
  def map(state) do
    Enum.reduce(state, %{}, fn
      %Op{ term: :header }, acc -> acc
      %Op{ location: loc, atoms: [] }, acc -> acc
      %Op{ location: loc, atoms: [val] }, acc when is_float(val) ->
        Map.put(acc, loc, Float.round(val, 5))
      %Op{ location: loc, atoms: [val] }, acc ->
        Map.put(acc, loc, val)
    end)
  end
end

