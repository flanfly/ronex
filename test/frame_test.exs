defmodule FrameTest do
  use ExUnit.Case
  doctest Frame

  test "basic decode" do
    txt = "  \n*rga#1UQ8p+bart@1UQ8yk+lisa:0!\n    @(s+bart'H'@[r'e'@(t'l'@[T'l'@[i'o'\n    @(w+lisa' '@(x'w'@(y'o'@[1'r'@{a'l'@[2'd'@[k'!'"
    {:ok, frame} = Frame.parse(txt)

    assert length(frame) == 13
  end

  test "decode first" do
    txt = "*lww#test1!\n    *lww#test1@time:a'A';"
    {:ok, frame} = Frame.parse(txt)

    assert length(frame) == 2
  end

  test "decode nothing" do
    {:ok, frame} = Frame.parse("")
    assert length(frame) == 0

    {:ok, frame} = Frame.parse(".")
    assert length(frame) == 0
  end

  test "decode error" do
   {:error, _} = Frame.parse("XX")
  end

  test "split frame" do
    txt = "*lww#test1!\n    *lww#test1@time:a'A';"
    [f1 | [f2 | []]] = Frame.parse!(txt) |> Frame.split

    assert length(f1) == 1
    assert length(f2) == 1
  end
end
