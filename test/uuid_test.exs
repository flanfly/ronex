defmodule UUIDTest do
  use ExUnit.Case
  doctest UUID

  test "now" do
    assert UUID.now() == %UUID{ hi: 0, lo: 0 }
  end

  test "null" do
    assert UUID.null() |> UUID.to_text == "0"
  end

  test "names" do
    assert %UUID{ hi: 824893205576155136, lo: 0, scheme: :name } |> UUID.to_text == "inc"
  end
end
