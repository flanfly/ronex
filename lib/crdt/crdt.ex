defprotocol CRDT do
  @doc "Conflict-free, repicated data type"

  def reduce(frames)
  def map(state)
end
