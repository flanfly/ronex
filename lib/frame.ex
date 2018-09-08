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
      {"", prev} -> :nil
      {str, prev} ->
        case Op.from_text(str, prev) do
          {:ok, {op, cdr}} -> {op, {cdr, op}}
          {:error, msg} -> {{:error, msg}, {"", prev}}
        end
    end)
  end
end
