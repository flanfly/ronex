defmodule Frame do
  defstruct type: :nil, data: :nil

  def from_text(str) do
    %Frame{ type: :text, data: str }
  end

  def stream(%UUID{ }) do
    :nil
  end

  def ops(%Frame{ type: :text, data: str }) do
    prev = %Op{ type: :nil, event: :nil, object: :nil, location: :nil }
    Stream.unfold({str, prev}, fn
      {"", _} -> :nil
      {str, prev} ->
        case Op.from_text(str, prev) do
          {:ok, {op, cdr}} -> {op, {cdr, op}}
          {:error, msg} -> {{:error, msg}, {"", prev}}
        end
    end)
  end

  def chunks(frm = %Frame{}) do
    Frame.ops(frm) |> Stream.chunk_while([], fn
      op = %Op{ term: :raw }, [] ->
        {:cont, [op], []}
      op = %Op{ term: :raw }, ops ->
        {:cont, ops, [op]}
      op = %Op{ term: :header }, [] ->
        {:cont, [op]}
      op = %Op{ term: :header }, ops ->
        {:cont, ops, [op]}
      op = %Op{ term: :query }, [] ->
        {:cont, [op]}
      op = %Op{ term: :query }, ops ->
        {:cont, ops, [op]}
      # reduced op w/o preceeding header: insert artificial header
      op = %Op{ term: :reduced }, [] ->
        {:cont, [%Op{op | term: :header, atoms: [], location: UUID.null()}, op]}
      op = %Op{ term: :reduced }, ops = [%Op{ term: :header } | _] ->
        {:cont, ops ++ [op]}
      op = %Op{ term: :reduced }, ops = [%Op{ term: :query } | _] ->
        {:cont, ops ++ [op]}
      op = %Op{ term: :reduced }, [ops = %Op{ term: :raw }] ->
        {:cont, ops, [%Op{op | term: :header, atoms: [], location: UUID.null()}, op]}
        # end op w/o preceeding header: insert artificial header
      op = %Op{ term: :end }, [] ->
        {:cont, [%Op{op | term: :header}, op]}
      op = %Op{ term: :end }, ops = [%Op{ term: :header } | _] ->
        {:cont, ops ++ [op], []}
      op = %Op{ term: :end }, ops = [%Op{ term: :query } | _] ->
        {:cont, ops ++ [op], []}
      op = %Op{ term: :end }, [ops = %Op{ term: :raw }] ->
        {:cont, ops, [op]}
     end,
    fn
      [] -> {:cont, []}
      ops -> {:cont, ops, []}
    end)
  end
end
