defmodule SetTest do
  use ExUnit.Case
  doctest Set

  test "ron-test 04-set-basic" do
    st1 = "*set#test1@1=1;"
    up1 = "*set#test1@2=2;"
    out1 = "*set#test1@2:1!:0=2@1=1"
    test_set(st1, up1, out1)

    st2 = "*set#test2@1!@=1"
    up2 = "*set#test2@2:1;"
    out2 = "*set#test2@2!:1,"
    test_set(st2, up2, out2)

    st3 = "*set#test3@3:1;"
    up3 =  "*set#test3@4:2;";
    out3 = "*set#test3@4:d!:2,@3:1,"
    test_set(st3, up3, out3)

    st4 = "*set#test4@2!@=2@1=1"
    up4 = "*set#test4@5!@=5@3:2,@4:1,"
    out4 = "*set#test4@5!@=5@3:2,@4:1,"
    test_set(st4, up4, out4)

    st5 = "*set#test5@2!@=2@1=1"
    up5 = "*set#test5@3!@:2,@4:1,.\n*set#test5@5!@=5"
    out5 = "*set#test5@5!@=5@3:2,@4:1,"
    test_set(st5, up5, out5)

    st6 = "*set#test6@3!@:2,@4:1,"
    up6 = "*set#test6@5!@=5\n*set#test6@2!@=2@1=1\n"
    out6 = "*set#test6@5000000001!@5=5@3:2,@4:1,"
    test_set(st6, up6, out6)

    st7 = "*set#mice@1YKDY54a01+1YKDY5!>mouse$1YKDY5"
    up7 = "*set#mice@1YKDXO3201+1YKDXO?!@>mouse$1YKDXO@(WBF901(WBY>mouse$1YKDWBY@[67H01[6>mouse$1YKDW6@(Uh4j01(Uh>mouse$1YKDUh@(S67V01(S6>mouse$1YKDS6@(Of(N3:1YKDN3DS01+1YKDN3,@(MvBV01(IuJ:0>mouse$1YKDIuJ@(LF:1YKDIuEY01+1YKDIuJ,:{A601,@(Io5l01[oA:0>mouse$1YKDIoA@[l7_01[l>mouse$1YKDIl@(57(4B:1YKD4B3f01+1YKD4B,@(0bB401+1YKCsd:0>mouse$1YKCsd@1YKCu6+:1YKCsd7Q01+1YKCsd,"
    out7 = "*set#mice@1YKDXO3201+1YKDXO!@(Y54a01(Y5>mouse$1YKDY5@(XO3201(XO>mouse$1YKDXO@(WBF901(WBY>mouse$1YKDWBY@[67H01[6>mouse$1YKDW6@(Uh4j01(Uh>mouse$1YKDUh@(S67V01(S6>mouse$1YKDS6@(Of(N3:1YKDN3DS01+1YKDN3,@(MvBV01(IuJ:0>mouse$1YKDIuJ@(LF:1YKDIuEY01+1YKDIuJ,:{A601,@(Io5l01[oA:0>mouse$1YKDIoA@[l7_01[l>mouse$1YKDIl@(57(4B:1YKD4B3f01+1YKD4B,@(0bB401+1YKCsd:0>mouse$1YKCsd@1YKCu6+:1YKCsd7Q01+1YKCsd,"
    test_set(st7, up7, out7)
  end

  test "ron set_test" do
    st1 = "*set#test1@1=1"
    up1 = "*set#test1@2=2"
    out1 = "*set#test1@2:d!:0=2@1=1"
    test_set(st1, up1, out1)

    st2 = "*set#test1@1!@=1"
    up2 = "*set#test1@2:1;"
    out2 = "*set#test1@2!:1,"
    test_set(st2, up2, out2)

    st3 = "*set#test1@3:1;"
    up3 = "*set#test1@4:2;"
    out3 = "*set#test1@4:d!:2,@3:1,"
    test_set(st3, up3, out3)

    st4 = "*set#test1@2!@=2@1=1"
    up4 = "*set#test1@5!@=5@3:2,@4:1,"
    out4 = "*set#test1@5!@=5@3:2,@4:1,"
    test_set(st4, up4, out4)

    st5 = "*set#test1@2!@=2@1=1"
    up5 = "*set#test1@3!@:2,@4:1,.*set#test1@5!@=5"
    out5 = "*set#test1@5!@=5@3:2,@4:1,"
    test_set(st5, up5, out5)

    st6 = "*set#test1@3!@:2,@4:1"
    up6 = "*set#test1@5!@=5.*set#test1@2!@=2@1=1"
    out6 = "*set#test1@2!@5=5@3:2,@4:1,"
    test_set(st6, up6, out6)
  end

  defp test_set(state, updates, output) do
    {state, _} = Frame.parse!(state)
    updates = Batch.parse!(updates)
    {output, _} = Frame.parse!(output)

    final = Enum.reduce(updates, state, fn update, state -> Set.reduce(state, update) end)
    final = Set.map(final)
    expected = Set.map(output)

    IO.inspect final
    IO.inspect expected

    assert final == expected
  end
end
