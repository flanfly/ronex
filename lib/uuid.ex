defmodule UUID do
  defstruct hi: 0, lo: 0, scheme: :event

  def zero(), do: %UUID{ hi: 0, lo: 0, scheme: :name }
  def now(), do: %UUID{ hi: 0, lo: 0, scheme: :event }
  def now_from(origin), do: %UUID{ hi: 0, lo: origin, scheme: :event }

  def name(name) do
    %UUID{ hi: UUID.parse(name), lo: 0, scheme: :name }
  end

  def scoped_name(name, scope) do
    %UUID{
      hi: UUID.parse(name),
      lo: UUID.parse(scope),
      scheme: :name
    }
  end

  def error() do
    %UUID{ hi: 1152921504606846975, lo: 0, scheme: :name }
  end

  def never() do
    %UUID{ hi: 1134907106097364992, lo: 0, scheme: :event }
  end

  def is_less?(%UUID{ hi: hi1, lo: lo1 }, %UUID{ hi: hi2, lo: lo2 }) do
    if hi1 == hi2 do lo1 < lo2 else hi1 < hi2 end
  end

  def is_zero?(%UUID{ hi: 0 }), do: true
  def is_zero?(_), do: false

  def parse(str), do: parse(str, UUID.zero(), UUID.zero())
  def parse(str, prev_column, prev_row) do
    init = {0, 0, 0, 0, :name}
    parse(str, prev_column, prev_row, init)
  end

  defp parse("", prev_column, _, {_, 0, _, 0, _}) do
    {:ok, {prev_column, ""}}
  end

  defp parse("", _, _, {hi, _, lo, _, sch}) do
    {:ok, {%UUID{ hi: hi, lo: lo, scheme: sch}, ""}}
  end

  defp parse(str, prev_column, prev_row, {hi, hi_bits, lo, lo_bits, sch}) do
    use Bitwise

    str = String.trim_leading(str)
    car = String.first(str) |> :binary.first
    cdr = String.slice(str, 1..-1)
    is_parse_char = car in ?0..?9 or car in ?a..?z
      or car in ?A..?Z or car == ?~ or car == ?_

    case car do
      _ when is_parse_char ->
        val = case car do
          car when car in ?0..?9 -> car - ?0
          car when car in ?A..?Z -> car - ?A + 10
          ?_ -> 36
          car when car in ?a..?z -> car - ?a + 37
          ?~ -> 63
        end

        state = case hi_bits do
          10 ->
            i = 9 - lo_bits
            { hi, hi_bits,
              lo ||| (val <<< (6 * i)), lo_bits + 1,
              sch }
          x when x in 0..9 ->
            i = 9 - hi_bits
            { hi ||| (val <<< (6 * i)), hi_bits + 1,
              lo, lo_bits,
              sch }
        end

        parse(cdr, prev_column, prev_row, state)

      ?( when prev_column != :nil and hi_bits == 0 ->
        parse(cdr, prev_column, prev_row, {prev_column.hi >>> 6, 4, 0, 0, sch})
      ?( when prev_column != :nil and lo_bits == 0 ->
        parse(cdr, prev_column, prev_row, {hi, hi_bits, prev_column.lo >>> 6, 4, sch})
      ?( -> {:error, "( prefix inside UUID."}

      ?[ when prev_column != :nil and hi_bits == 0 ->
        parse(cdr, prev_column, prev_row, {prev_column.hi >>> 5, 5, 0, 0, sch})
      ?[ when prev_column != :nil and lo_bits == 0 ->
        parse(cdr, prev_column, prev_row, {hi, hi_bits, prev_column.lo >>> 5, 5, sch})
      ?[ -> {:error, "[ prefix inside UUID."}

      ?{ when prev_column != :nil and hi_bits == 0 ->
        parse(cdr, prev_column, prev_row, {prev_column.hi >>> 4, 6, 0, 0, sch})
      ?{ -> {:error, "{ prefix inside UUID."}

      ?} when prev_column != :nil and hi_bits == 0 ->
        parse(cdr, prev_column, prev_row, {prev_column.hi >>> 3, 7, 0, 0, sch})
      ?} -> {:error, "} prefix inside UUID."}

      ?] when prev_column != :nil and hi_bits == 0 ->
        parse(cdr, prev_column, prev_row, {prev_column.hi >>> 2, 8, 0, 0, sch})
      ?] -> {:error, "] prefix inside UUID."}

      ?) when prev_column != :nil and hi_bits == 0 ->
        parse(cdr, prev_column, prev_row, {prev_column.hi >>> 1, 9, 0, 0, sch})
      ?) when prev_column != :nil and lo_bits == 0 ->
        parse(cdr, prev_column, prev_row, {hi, hi_bits, prev_column.lo >>> 1, 9, sch})
      ?) -> {:error, ") prefix inside UUID."}

      ?` when prev_row != :nil and hi_bits == 0 ->
        {:ok, {prev_row, str}}
      ?` -> {:error, "` prefix inside UUID."}

      ?+ when lo_bits == 0 -> parse(cdr, prev_column, prev_row, {hi, 10, 0, 0, :derived})
      ?% when lo_bits == 0 -> parse(cdr, prev_column, prev_row, {hi, 10, 0, 0, :hash})
      ?- when lo_bits == 0 -> parse(cdr, prev_column, prev_row, {hi, 10, 0, 0, :event})
      ?$ when lo_bits == 0 -> parse(cdr, prev_column, prev_row, {hi, 10, 0, 0, :name})

      _ ->
        cond do
          hi == 0 and lo == 0 and hi_bits == 0 and lo_bits == 0 ->
            {:ok, {prev_column, str}}
          hi == 0 and lo == 0 ->
            {:ok, {UUID.zero(), str}}
          true ->
            {:ok, {%UUID{ hi: hi, lo: lo, scheme: sch }, str}}
        end
    end
  end
end

defimpl String.Chars, for: UUID do
  def to_string(%UUID{ hi: 0, lo: 0 }), do: "0"
  def to_string(%UUID{ hi: hi, lo: 0, scheme: :name }), do: int_to_text(hi)
  def to_string(%UUID{ hi: hi, lo: lo, scheme: :name }) do
    int_to_text(hi) <> "$" <> int_to_text(lo)
  end
  def to_string(%UUID{ hi: hi, lo: lo, scheme: :hash }) do
    int_to_text(hi) <> "%" <> int_to_text(lo)
  end
  def to_string(%UUID{ hi: hi, lo: lo, scheme: :derived }) do
    int_to_text(hi) <> "+" <> int_to_text(lo)
  end
  def to_string(%UUID{ hi: hi, lo: lo, scheme: :event }) do
    int_to_text(hi) <> "-" <> int_to_text(lo)
  end

  defp int_to_text(int) do
    use Bitwise

    str = Enum.map(0..10, fn idx ->
      idx = (9 - idx) * 6
        val = (int >>> idx) &&& 63

        case val do
          x when x in 0..9 -> ?0 + x
          x when x in 10..35 -> ?A + x - 10
          36 -> ?_
          x when x in 37..62 -> ?a + x - 37
          63 -> ?~
        end
    end) |> List.to_string |> String.trim_trailing("0")

    if String.length(str) == 0 do
      "0"
    else
      str
    end
  end
end


defimpl Inspect, for: UUID do
  def inspect(uuid, _), do: to_string uuid
end
