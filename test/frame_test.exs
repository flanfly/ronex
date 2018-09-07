defmodule FrameTest do
  use ExUnit.Case
  doctest Frame

  test "decode text" do
    txt = "  \n*rga#1UQ8p+bart@1UQ8yk+lisa:0!\n    @(s+bart'H'@[r'e'@(t'l'@[T'l'@[i'o'\n    @(w+lisa' '@(x'w'@(y'o'@[1'r'@{a'l'@[2'd'@[k'!'"
    frame = Frame.decode_op(txt, {:nil, :nil, :nil, :nil})
    IO.inspect frame 
    
    frame == :ok
  end
end
