defmodule FrameTest do
  use ExUnit.Case
  doctest Frame

  test "decode text" do
    txt = "  \n*rga#1UQ8p+bart@1UQ8yk+lisa:0!\n    @(s+bart'H'@[r'e'@(t'l'@[T'l'@[i'o'\n    @(w+lisa' '@(x'w'@(y'o'@[1'r'@{a'l'@[2'd'@[k'!'"
    Frame.parse(txt)
  end

  test "ron-tests 01-lww-basic" do
    t1 = "*lww#test1!\n    *lww#test1@time:a'A';"
    t2 = "*lww#test2@1:0!:a'A'\n *lww#test2@2:b'B';"
    t3 = "*lww#test3@1:a'A1';*lww#test3@2:a'A2';"
    t4 = "*lww#test4@2:1!     :a  'A1'    :b  'B1'    :c  'C1'*lww#test4@3:1!     :a  'A2'    :b  'B2'"
    t5 = "*lww#array@1:0!    :0%0 =0,      :)1%0 =-1*lww#array@2:0!     :0%)1 '1',      :)1%0 =1,      :)1%)1 =65536"
    t6 = "*lww#weird@0:0!*lww#weird@1 :longString 'While classic databases score 0 on the ACID\\' scale, I should probably reserve the value of -1 for one data sync system based on Operational Transforms.\\n Because of the way its OT mechanics worked, even minor glitches messed up the entire database through offset corruption. That was probably the worst case I observed in the wild. Some may build on quicksand, others need solid bedrock… but that system needed a diamond plate to stay still.' ;*lww#weird@2 :pi ^3.141592653589793 ;*lww#weird@3 :minus =-9223372036854775808 ;"
    t7 = "    *lww#raw@1:one=1;@2:two^2.0:three'три'"
    txt = [t1,t2,t3,t4,t5,t6,t7]

    Enum.each(txt, fn txt ->
      {frm, _} = Frame.parse(txt)
      frm |> Frame.ops |> Stream.run
    end)
  end
end
