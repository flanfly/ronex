defmodule Frame do
  defstruct type: :nil, data: :nil

  def parse(frm), do: parse(frm, "", :outside)
  defp parse("." <> cdr, frm, :outside), do: {%Frame{ type: :text, data: frm }, cdr}
  defp parse("", frm, _), do: {%Frame{ type: :text, data: frm }, ""}
  defp parse(cdr, frm, state) do
    char = String.first(cdr)
    case {char, state} do
      {"^", :outside} -> parse(String.slice(cdr, 1..-1), frm <> char, :number)
      {"'", :outside} -> parse(String.slice(cdr, 1..-1), frm <> char, :inside)
      {"'", :escaped} -> parse(String.slice(cdr, 1..-1), frm <> char, :inside)
      {"'", :inside} -> parse(String.slice(cdr, 1..-1), frm <> char, :outside)
      {"\\", :inside} -> parse(String.slice(cdr, 1..-1), frm <> char, :escaped)
      {_, :escaped} -> parse(String.slice(cdr, 1..-1), frm <> char, :inside)
      {".", :outside} -> {%Frame{ type: :text, data: frm }, String.slice(cdr, 1..-1)}
      {c, :number} ->
        is_num_char = ?c in ?0..?9 or c == "-" or c == "+" or c
        if is_num_char do
          parse(String.slice(cdr, 1..-1), frm <> char, :number)
        else
          parse(String.slice(cdr, 1..-1), frm <> char, :outside)
        end
      {_, _} -> parse(String.slice(cdr, 1..-1), frm <> char, state)
    end
  end

  def ops(%Frame{ type: :text, data: str }) do
    init = %Op{ type: :nil, event: :nil, object: :nil, location: UUID.zero() }
    Stream.unfold({str, init}, fn
      {"", _} -> :nil
      {str, prev} ->
        case Op.parse(str, prev) do
          {:ok, {op, cdr}} ->
            cdr = String.trim_leading(cdr)
            {next_prev, cdr} = case cdr do
              "." <> _ -> {init, String.slice(cdr, 1..-1)}
              "" -> {init, ""}
              _ -> case op do
                %Op{ term: :reduced } -> {op, cdr}
                %Op{ term: :header } -> {op, cdr}
                %Op{ term: :raw } -> {init, cdr}
                %Op{ term: :query } -> {op, cdr}
              end
            end

            {{:ok, op}, {cdr, next_prev}}

          {:error, msg} -> {{:error, msg}, {"", prev}}
        end
    end)
  end

  def ops!(frame) do
    ops(frame) |> Stream.map(fn
      {:ok, op} -> op
      {:error, msg} -> raise msg
    end)
  end

  def chunks(frm = %Frame{}) do
    Frame.ops(frm) |> Stream.chunk_while([], fn
      {:ok, op = %Op{ term: :raw }}, [] ->
        {:cont, [op], []}
      {:ok, op = %Op{ term: :raw }}, ops ->
        {:cont, ops, [op]}
      {:ok, op = %Op{ term: :header }}, [] ->
        {:cont, [op]}
      {:ok, op = %Op{ term: :header }}, ops ->
        {:cont, ops, [op]}
      {:ok, op = %Op{ term: :query }}, [] ->
        {:cont, [op]}
      {:ok, op = %Op{ term: :query }}, ops ->
        {:cont, ops, [op]}
      {:ok, %Op{ term: :reduced }}, [] ->
        {:halt, {:error , "reduced op w/o preceeding header"}}
      {:ok, op = %Op{ term: :reduced }}, ops = [%Op{ term: :header } | _] ->
        {:cont, ops ++ [op]}
      {:ok, op = %Op{ term: :reduced }}, ops = [%Op{ term: :query } | _] ->
        {:cont, ops ++ [op]}
      {:ok, %Op{ term: :reduced }}, [%Op{ term: :raw }] ->
        {:halt, {:error , "reduced op w/o preceeding header"}}
      {:error, msg}, _ ->
        {:halt, {:error , msg}}
      end,
    fn
      [] -> {:cont, []}
      ops -> {:cont, ops, []}
    end)
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
  defstruct frames: []

  def parse(str), do: parse(str, [])
  def parse(str, batch) do
    str = String.trim_leading(str)
    if str == "" do
      %Batch{ frames: batch }
    else
      {frame, cdr} = Frame.parse(str)
      parse(cdr, batch ++ [frame])
    end
  end

  def ops(%Batch{ frames: frames  }) do
    Enum.reduce(frames, Stream.map([], &(&1)), fn frm, strm ->
      Stream.concat(strm, Frame.ops(frm))
    end)
  end

  def ops!(batch) do
    ops(batch)
    |> Stream.map(fn
      {:ok, op} -> op
      {:error, msg} -> raise msg
    end)
  end
end
