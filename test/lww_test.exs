defmodule LWWTest do
  use ExUnit.Case
  doctest LWW

  test "ron-tests 01-lww-basic" do
    st1 = "*lww#test1!"
    up1 = "*lww#test1@time:a'A';"
    out1 = "*lww#test1@time:0!\n      :a      'A' ,"
    test_lww(st1, up1, out1)

    st2 = "*lww#test2@1:0!:a'A'"
    up2 = "*lww#test2@2:b'B';"
    out2 = "*lww#test2@2:0!\n    @1  :a      'A' ,\n    @2  :b      'B' ,"
    test_lww(st2, up2, out2)

    st3 = "*lww#test3@1:a'A1';"
    up3 = "*lww#test3@2:a'A2';"
    out3 = "*lww#test3@2:1!\n        :a      'A2' ,"
    test_lww(st3, up3, out3)

    st4 = "*lww#test4@2:1!\n    :a  'A1'\n    :b  'B1'\n    :c  'C1'"
    up4 = "*lww#test4@3:1! \n    :a  'A2'\n    :b  'B2'\n"
    out4 = "*lww#test4@3:1!\n        :a      'A2' ,\n        :b      'B2' ,\n    @2  :c      'C1' ,\n"
    test_lww(st4, up4, out4)

    st5 = "*lww#array@1:0!\n    :0%0 =0,  \n    :)1%0 =-1"
    up5 = "*lww#array@2:0! \n    :0%)1 '1',  \n    :)1%0 =1,  \n    :)1%)1 =65536\n"
    out5 = "*lww#array@2:0!\n     @1  :0%0      =0  ,\n    @2  :0%0000000001    '1' ,\n        :0000000001%0    =1  ,\n        :0000000001%0000000001    =65536  ,"
    test_lww(st5, up5, out5)

    st6 = "*lww#weird@0:0!"
    up6 = "*lww#weird@1 :longString 'While classic databases score 0 on the ACID\\' scale, I should probably reserve the value of -1 for one data sync system based on Operational Transforms.\n Because of the way its OT mechanics worked, even minor glitches messed up the entire database through offset corruption. That was probably the worst case I observed in the wild. Some may build on quicksand, others need solid bedrock… but that system needed a diamond plate to stay still.' ;\n*lww#weird@2 :pi ^3.141592653589793 ;\n*lww#weird@3 :minus =-9223372036854775808 ;\n"
    out6 = "*lww#weird@3:0!\n	@1 :longString 'While classic databases score 0 on the ACID\\' scale, I should probably reserve the value of -1 for one data sync system based on Operational Transforms.\n Because of the way its OT mechanics worked, even minor glitches messed up the entire database through offset corruption. That was probably the worst case I observed in the wild. Some may build on quicksand, others need solid bedrock… but that system needed a diamond plate to stay still.' ,\n	@3 :minus =-9223372036854775808 ,\n	@2 :pi ^3.141593e+00 ,"
    test_lww(st6, up6, out6)

    st7 = "*lww#raw@1:one=1;"
    up7 = "*lww#raw@2:two^2.0:three'три'"
    out7 = "*lww#raw@2:1!\n	@1 :one =1 ,\n	@2 :three 'три' ,\n  :two ^2.000000e+00 ,"
    test_lww(st7, up7, out7)
  end

  defp test_lww(state, updates, output) do
    {state, _} = Frame.parse!(state)
    updates = Batch.parse!(updates)
    {output, _} = Frame.parse!(output)

    final = Enum.reduce(updates, state, fn update, state -> LWW.reduce(state, update) end)
    final = LWW.map(final)
    expected = LWW.map(output)

    IO.inspect final
    IO.inspect expected

    assert final == expected
  end
end
