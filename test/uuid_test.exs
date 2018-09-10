defmodule UUIDTest do
  use ExUnit.Case
  doctest UUID

  test "now" do
    assert UUID.now() == %UUID{ hi: 0, lo: 0 }
  end

  test "zero" do
    assert UUID.zero() |> to_string == "0"
    assert UUID.zero() |> UUID.is_zero?
  end

  test "names" do
    assert %UUID{ hi: 824893205576155136, lo: 0, scheme: :name } |> to_string == "inc"
  end

  test "parse" do
    assert {:ok, _} = UUID.parse("1")
  end
end
