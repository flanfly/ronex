defmodule UUID do
  defstruct hi: 0, lo: 0, scheme: :event

  def now() do
    %UUID{ hi: 0, lo: 0, scheme: :event }
  end

  def now_from(origin) do
    %UUID{ hi: 0, lo: origin, scheme: :event }
  end

  def name(name) do
    %UUID{ hi: UUID.decode_b64(name), lo: 0, scheme: :name }
  end

  def scoped_name(name, scope) do
    %UUID{
      hi: UUID.decode_b64(name),
      lo: UUID.decode_b64(scope),
      scheme: :name
    }
  end

  def error() do
    %UUID{ hi: UUID.encode_b64('~~~~~~~~~~'), lo: 0, scheme: :name }
  end

  def never() do
    %UUID{ hi: UUID.encode_b64('~'), lo: 0, scheme: :event }
  end

  defp encode_b64(val) do
    ""
  end

  defp decode_b64(s) do
    1
  end
end
