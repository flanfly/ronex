defmodule Set do
  def reduce([]), do: []
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
        au = if UUID.is_zero?(a.location) do a.event else a.location end
        bu = if UUID.is_zero?(b.location) do b.event else b.location end

        if au == bu do UUID.is_less?(b.location, a.location)
        else UUID.is_less?(bu, au) end
      end)
      |> Enum.chunk_by(fn %Op{ location: loc, event: ev } ->
        if UUID.is_zero?(loc) do ev else loc end end)
      |> Enum.map(fn [op | _] -> op end)
    ]
  end

  def map([]), do: MapSet.new()
  def map(state) do
    Enum.reduce(state, MapSet.new(), fn
      %Op{ term: :header }, acc -> acc
      %Op{ term: :query }, acc -> acc
      %Op{ location: loc, atoms: [val | _] }, acc ->
        if UUID.is_zero?(loc) do MapSet.put(acc, val) else acc end
      _, acc -> acc
    end)
  end
end

