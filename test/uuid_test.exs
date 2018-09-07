defmodule UUIDTest do
  use ExUnit.Case
  doctest UUID

  test "now" do
    assert UUID.now() == %UUID{ hi: 0, lo: 0 }
  end
end
