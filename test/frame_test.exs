defmodule FrameTest do
  use ExUnit.Case
  doctest Frame

  test "basic decode" do
    txt = "  \n*rga#1UQ8p+bart@1UQ8yk+lisa:0!\n    @(s+bart'H'@[r'e'@(t'l'@[T'l'@[i'o'\n    @(w+lisa' '@(x'w'@(y'o'@[1'r'@{a'l'@[2'd'@[k'!'"
    {:ok, frame, cdr} = Frame.parse(txt)

    assert cdr == ""
    assert length(frame) == 13
  end

  test "decode first" do
    txt = "*lww#test1!\n    *lww#test1@time:a'A';"
    {:ok, frame, cdr} = Frame.parse(txt)

    assert cdr == "*lww#test1@time:a'A';"
    assert length(frame) == 1
  end

  test "decode nothing" do
   {:ok, frame, cdr} = Frame.parse("")
    assert cdr == ""
    assert length(frame) == 0

    {:ok, frame, cdr} = Frame.parse(".")
    assert cdr == ""
    assert length(frame) == 0
  end

  test "decode error" do
   {:error, _} = Frame.parse("XX")
  end

  test "decode batch" do
    txt = "*lww#test1!\n    *lww#test1@time:a'A';"
    {:ok, [f1 | [f2 | []]]} = Batch.parse(txt)

    assert length(f1) == 1
    assert length(f2) == 1
  end
end
