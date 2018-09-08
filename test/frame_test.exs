defmodule FrameTest do
  use ExUnit.Case
  doctest Frame

  test "decode text" do
    txt = "  \n*rga#1UQ8p+bart@1UQ8yk+lisa:0!\n    @(s+bart'H'@[r'e'@(t'l'@[T'l'@[i'o'\n    @(w+lisa' '@(x'w'@(y'o'@[1'r'@{a'l'@[2'd'@[k'!'"
    Frame.from_text(txt) |> Frame.ops |> IO.inspect
  end

  test "ron-tests 01-lww-basic" do
    txt = "*lww#test1!
*lww#test1@time:a'A';

*lww#test2@1:0!:a'A'
*lww#test2@2:b'B';

*lww#test3@1:a'A1';
*lww#test3@2:a'A2';

*lww#test4@2:1! 
    :a  'A1'
    :b  'B1'
    :c  'C1'
*lww#test4@3:1! 
    :a  'A2'
    :b  'B2'

*lww#array@1:0!
    :0%0 =0,  
    :)1%0 =-1
*lww#array@2:0! 
    :0%)1 '1',  
    :)1%0 =1,  
    :)1%)1 =65536

*lww#weird@0:0!
*lww#weird@1 :longString 'While classic databases score 0 on the ACID\\' scale, I should probably reserve the value of -1 for one data sync system based on Operational Transforms.\\n Because of the way its OT mechanics worked, even minor glitches messed up the entire database through offset corruption. That was probably the worst case I observed in the wild. Some may build on quicksand, others need solid bedrock… but that system needed a diamond plate to stay still.' ;
*lww#weird@2 :pi ^3.141592653589793 ;
*lww#weird@3 :minus =-9223372036854775808 ;

*lww#raw@1:one=1;@2:two^2.0:three'три'
"
    Frame.from_text(txt) |> Frame.ops |> Enum.to_list |> IO.inspect
    Frame.from_text(txt) |> Frame.chunks |> Enum.to_list |> IO.inspect
  end
end
