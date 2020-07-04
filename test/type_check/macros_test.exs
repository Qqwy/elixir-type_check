defmodule TypeCheck.MacrosTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []
  import TypeCheck.Type.StreamData

  doctest TypeCheck.Macros

  describe "basic type definition" do
    defmodule BasicTypeDefinition do
      use TypeCheck

      type mylist :: list(integer())
    end

    test "is exported as function" do
      assert {:mylist, 0} in BasicTypeDefinition.__info__(:functions)
      assert TypeCheck.Type.is_type?(BasicTypeDefinition.mylist())
    end

    property "can be turned into a StreamData generator" do
      gen = to_gen(BasicTypeDefinition.mylist())
      check all x <- gen do
        assert is_list(x)
        assert Enum.all?(x, fn elem -> is_integer(elem) end)
      end
    end
  end
end
