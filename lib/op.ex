defmodule Op do
  defstruct type: :nil, object: :nil, event: UUID.now(), location: :nil, atoms: [], terminator: :raw
end
