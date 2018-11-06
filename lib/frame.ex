defmodule Frame do
  defstruct type: :nil, data: :nil

  # Parse until EOF
  def parse(str), do: parse_impl(str, [])
  defp parse_impl("", ops), do: {:ok, ops}
  defp parse_impl("." <> _, ops), do: {:ok, ops}
  defp parse_impl("\t" <> cdr, ops), do: parse_impl(cdr, ops)
  defp parse_impl("\n" <> cdr, ops), do: parse_impl(cdr, ops)
  defp parse_impl("\r" <> cdr, ops), do: parse_impl(cdr, ops)
  defp parse_impl("\v" <> cdr, ops), do: parse_impl(cdr, ops)
  defp parse_impl(" " <> cdr, ops), do: parse_impl(cdr, ops)
  defp parse_impl(str, ops) do
    prev = case ops do
      [] ->
        %Op{
          type: UUID.zero(), event: UUID.zero(),
          object: UUID.zero(), location: UUID.zero()
        }
      ops -> List.last(ops)
    end

    case Op.parse(str, prev) do
      {:ok, {op, cdr}} ->
        if ops == [] do
          parse_impl(cdr, [op])
        else
          #prev = List.last(ops)
          #%Op{ term: prev_term } = prev
          #%Op{ term: term } = op

          #if prev_term == :raw or term != :reduced do
          #  {:ok, ops, str}
          #else
          parse_impl(cdr, ops ++ [op])
          #end
        end

      err = {:error, _} -> err
    end
  end

  def parse!(str) do
    case parse(str) do
      {:ok, ops} -> ops
      {:error, msg} -> raise msg
    end
  end

  def split(frame) do
    Enum.chunk_while(frame, [],fn
      elem,[] -> {:cont, [elem]}
      elem = %Op{ term: :header },chunk -> {:cont, chunk, [elem]}
      elem = %Op{ term: :query },chunk -> {:cont, chunk, [elem]}
      elem = %Op{ term: :raw },chunk -> {:cont, chunk, [elem]}
      elem = %Op{ term: :reduced },chunk = [%Op{ term: :header } | _] ->
        {:cont, chunk ++ [elem]}
      elem = %Op{ term: :reduced },chunk -> {:cont, chunk, [elem]}
    end, fn
      [] -> {:cont, []}
      chunk -> {:cont, chunk, []}
    end)
  end
end

defimpl String.Chars, for: Frame do
  def to_string(frame) do
    Enum.reduce(frame, "", fn
      op, "" -> Kernel.to_string(op)
      op, acc -> acc <> " " <> Kernel.to_string(op)
    end)
  end
end
