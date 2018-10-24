defmodule Frame do
  defstruct type: :nil, data: :nil

  def parse(str), do: parse(str, [])
  defp parse("", ops), do: {:ok, ops, ""}
  defp parse("." <> cdr, ops), do: {:ok, ops, cdr}
  defp parse("\t" <> cdr, ops), do: parse(cdr, ops)
  defp parse("\n" <> cdr, ops), do: parse(cdr, ops)
  defp parse("\r" <> cdr, ops), do: parse(cdr, ops)
  defp parse("\v" <> cdr, ops), do: parse(cdr, ops)
  defp parse(" " <> cdr, ops), do: parse(cdr, ops)
  defp parse(str, ops) do
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
          parse(cdr, [op])
        else
          prev = List.last(ops)
          %Op{ term: prev_term } = prev
          %Op{ term: term } = op

          if prev_term == :raw or term != :reduced do
            {:ok, ops, str}
          else
            parse(cdr, ops ++ [op])
          end
        end

      err = {:error, _} -> err
    end
  end

  def parse!(str) do
    case parse(str) do
      {:ok, ops, cdr} -> {ops, cdr}
      {:error, msg} -> raise msg
    end
  end
end

defimpl String.Chars, for: Frame do
  def to_string(frame) do
    Enum.reduce(Frame.ops!(frame), "", fn
      op, "" -> Kernel.to_string(op)
      op, acc -> acc <> " " <> Kernel.to_string(op)
    end)
  end
end

defmodule Batch do
  def parse(str), do: parse(str, [])
  defp parse(str, batch) do
    case Frame.parse(str) do
      {:ok, [], cdr} -> {:ok, batch}
      {:ok, ops, ""} -> {:ok, batch ++ [ops]}
      {:ok, ops, cdr} -> parse(cdr, batch ++ [ops])
      err = {:error, _} -> err
    end
  end

  def parse!(str) do
    case parse(str) do
      {:ok, ops} -> ops
      {:error, msg} -> raise msg
    end
  end
end
