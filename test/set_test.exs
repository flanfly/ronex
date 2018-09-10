defmodule SetTest do
  use ExUnit.Case
  doctest Set

  test "ron-test 04-set-basic" do
    in1 = "*set#test1@1=1.*set#test1@2=2"
    out1 = "*set#test1@2:1!:0=2@1=1"
    test_pair(in1, out1)

    in2 = "*set#test2@1!@=1.*set#test2@2:1;"
    out2 = "*set#test2@2!:1,"
    test_pair(in2, out2)

    in3 = "*set#test3@3:1;*set#test3@4:2;";
    out3 = "*set#test3@4:d!:2,@3:1,"
    test_pair(in3, out3)

    in4 = "*set#test4@2!@=2@1=1.*set#test4@5!@=5@3:2,@4:1,"
    out4 = "*set#test4@5!@=5@3:2,@4:1,"
    test_pair(in4, out4)

    in5 = "*set#test5@2!@=2@1=1.*set#test5@3!@:2,@4:1,.\n*set#test5@5!@=5"
    out5 = "*set#test5@5!@=5@3:2,@4:1,"
    test_pair(in5, out5)

    in6 = "*set#test6@3!@:2,@4:1,.*set#test6@5!@=5\n*set#test6@2!@=2@1=1\n"
    out6 = "*set#test6@5000000001!@5=5@3:2,@4:1,"
    test_pair(in6, out6)

    in7 = "*set#mice@1YKDY54a01+1YKDY5!>mouse$1YKDY5\n*set#mice@1YKDXO3201+1YKDXO?!@>mouse$1YKDXO@(WBF901(WBY>mouse$1YKDWBY@[67H01[6>mouse$1YKDW6@(Uh4j01(Uh>mouse$1YKDUh@(S67V01(S6>mouse$1YKDS6@(Of(N3:1YKDN3DS01+1YKDN3,@(MvBV01(IuJ:0>mouse$1YKDIuJ@(LF:1YKDIuEY01+1YKDIuJ,:{A601,@(Io5l01[oA:0>mouse$1YKDIoA@[l7_01[l>mouse$1YKDIl@(57(4B:1YKD4B3f01+1YKD4B,@(0bB401+1YKCsd:0>mouse$1YKCsd@1YKCu6+:1YKCsd7Q01+1YKCsd,"
    out7 = "*set#mice@1YKDXO3201+1YKDXO!@(Y54a01(Y5>mouse$1YKDY5@(XO3201(XO>mouse$1YKDXO@(WBF901(WBY>mouse$1YKDWBY@[67H01[6>mouse$1YKDW6@(Uh4j01(Uh>mouse$1YKDUh@(S67V01(S6>mouse$1YKDS6@(Of(N3:1YKDN3DS01+1YKDN3,@(MvBV01(IuJ:0>mouse$1YKDIuJ@(LF:1YKDIuEY01+1YKDIuJ,:{A601,@(Io5l01[oA:0>mouse$1YKDIoA@[l7_01[l>mouse$1YKDIl@(57(4B:1YKD4B3f01+1YKD4B,@(0bB401+1YKCsd:0>mouse$1YKCsd@1YKCu6+:1YKCsd7Q01+1YKCsd,"
    test_pair(in7, out7)
  end

  test "ron set_test" do
    in1 = "*set#test1@1=1.*set#test1@2=2"
    out1 = "*set#test1@2:d!:0=2@1=1"
    test_pair(in1, out1)

    in2 = "*set#test1@1!@=1.*set#test1@2:1;"
    out2 = "*set#test1@2!:1,"
    test_pair(in2, out2)

    in3 = "*set#test1@3:1;*set#test1@4:2;"
    out3 = "*set#test1@4:d!:2,@3:1,"
    test_pair(in3, out3)

    in4 = "*set#test1@2!@=2@1=1.*set#test1@5!@=5@3:2,@4:1,"
    out4 = "*set#test1@5!@=5@3:2,@4:1,"
    test_pair(in4, out4)

    in5 = "*set#test1@2!@=2@1=1.*set#test1@3!@:2,@4:1,.*set#test1@5!@=5"
    out5 = "*set#test1@5!@=5@3:2,@4:1,"
    test_pair(in5, out5)

    in6 = "*set#test1@3!@:2,@4:1.*set#test1@5!@=5.*set#test1@2!@=2@1=1"
    out6 = "*set#test1@2!@5=5@3:2,@4:1,"
    test_pair(in6, out6)
  end

  defp test_pair(input, output) do
    input = (input |> Batch.parse |> Batch.ops! |> Enum.to_list)
    output = (output |> Batch.parse |> Batch.ops! |> Enum.to_list)
    input = Set.reduce(input)
    output = Set.reduce(output)

    assert Set.map(input) == Set.map(output)
  end
end
