defmodule TypeCheck.ExternalTest do
  use ExUnit.Case, async: true
  doctest TypeCheck.External
  alias TypeCheck.External, as: E

  describe "apply" do
    test "ok" do
      alias TypeCheck.Builtin, as: B
      type = B.function([B.number()], B.number())
      assert {:ok, 13} = E.apply(type, Kernel, :abs, [-13])
    end

    test "wrong param type" do
      alias TypeCheck.Builtin, as: B
      type = B.function([B.atom()], B.number())
      assert {:error, _} = E.apply(type, Kernel, :abs, [-13])
    end

    test "wrong result type" do
      alias TypeCheck.Builtin, as: B
      type = B.function([B.number()], B.atom())
      assert {:error, _} = E.apply(type, Kernel, :abs, [-13])
    end

    test "union of functions" do
      alias TypeCheck.Builtin, as: B

      type =
        B.one_of([
          B.function([B.number()], B.number()),
          B.function([B.atom()], B.atom())
        ])

      assert {:ok, 13} = E.apply(type, Function, :identity, [13])
      assert {:ok, :hi} = E.apply(type, Function, :identity, [:hi])
      assert {:error, _} = E.apply(type, Function, :identity, ["wow"])
    end
  end
end
