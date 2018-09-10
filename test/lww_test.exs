defmodule LWWTest do
  use ExUnit.Case
  doctest LWW

  test "ron-tests 01-lww-basic" do
    in1 = "*lww#test1!\n.*lww#test1@time:a'A';"
    out1 = "*lww#test1@time:0!\n      :a      'A' ,"
    test_pair(in1, out1)

    in2 = "*lww#test2@1:0!:a'A'\n.*lww#test2@2:b'B';"
    out2 = "*lww#test2@2:0!\n    @1  :a      'A' ,\n    @2  :b      'B' ,"
    test_pair(in2, out2)

    in3 = "*lww#test3@1:a'A1';\n*lww#test3@2:a'A2';"
    out3 = "*lww#test3@2:1!\n        :a      'A2' ,"
    test_pair(in3, out3)

    in4 = "*lww#test4@2:1!\n    :a  'A1'\n    :b  'B1'\n    :c  'C1'\n*lww#test4@3:1! \n    :a  'A2'\n    :b  'B2'\n"
    out4 = "*lww#test4@3:1!\n        :a      'A2' ,\n        :b      'B2' ,\n    @2  :c      'C1' ,\n"
    test_pair(in4, out4)

    in5 = "*lww#array@1:0!\n    :0%0 =0,  \n    :)1%0 =-1\n*lww#array@2:0! \n    :0%)1 '1',  \n    :)1%0 =1,  \n    :)1%)1 =65536\n"
    out5 = "*lww#array@2:0!\n     @1  :0%0      =0  ,\n    @2  :0%0000000001    '1' ,\n        :0000000001%0    =1  ,\n        :0000000001%0000000001    =65536  ,"
    test_pair(in5, out5)

    in6 = "*lww#weird@0:0!\n*lww#weird@1 :longString 'While classic databases score 0 on the ACID\\' scale, I should probably reserve the value of -1 for one data sync system based on Operational Transforms.\n Because of the way its OT mechanics worked, even minor glitches messed up the entire database through offset corruption. That was probably the worst case I observed in the wild. Some may build on quicksand, others need solid bedrock… but that system needed a diamond plate to stay still.' ;\n*lww#weird@2 :pi ^3.141592653589793 ;\n*lww#weird@3 :minus =-9223372036854775808 ;\n"
    out6 = "*lww#weird@3:0!\n	@1 :longString 'While classic databases score 0 on the ACID\\' scale, I should probably reserve the value of -1 for one data sync system based on Operational Transforms.\n Because of the way its OT mechanics worked, even minor glitches messed up the entire database through offset corruption. That was probably the worst case I observed in the wild. Some may build on quicksand, others need solid bedrock… but that system needed a diamond plate to stay still.' ,\n	@3 :minus =-9223372036854775808 ,\n	@2 :pi ^3.141593e+00 ,"
    test_pair(in6, out6)

    in7 = "*lww#raw@1:one=1;@2:two^2.0:three'три'"
    out7 = "*lww#raw@2:1!\n	@1 :one =1 ,\n	@2 :three 'три' ,\n  :two ^2.000000e+00 ,"
    test_pair(in7, out7)
  end


  defp test_pair(input, output) do
    input = (input |> Batch.parse |> Batch.ops! |> Enum.to_list)
    output = (output |> Batch.parse |> Batch.ops! |> Enum.to_list)
    input = Set.reduce(input)
    output = Set.reduce(output)

    assert LWW.map(input) == LWW.map(output)
  end
end
