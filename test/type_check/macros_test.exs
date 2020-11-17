defmodule TypeCheck.MacrosTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []
  import TypeCheck.Type.StreamData

  doctest TypeCheck.Macros

  describe "basic type definition" do
    defmodule BasicTypeDefinition do
      use TypeCheck

      @type! mylist :: list(integer())
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

    test "support unquote fragments" do
      defmodule UnquoteFragmentSpec do
        defmacro my_macro(name) do
          quote bind_quoted: [name: name], location: :keep do

            use TypeCheck
            spec! unquote(:"my_function_#{name}")(binary) :: binary
            def unquote(:"my_function_#{name}")(greeting) do
              greeting
            end
          end
        end
      end

      defmodule UnquoteFragmentSpecExample do
        require UnquoteFragmentSpec

        UnquoteFragmentSpec.my_macro("greeter")
      end

      assert TypeCheck.Spec.defined?(UnquoteFragmentSpecExample, :my_function_greeter, 1)
      assert UnquoteFragmentSpecExample.my_function_greeter("hi") == "hi"
      assert_raise(TypeCheck.TypeError, fn ->
        UnquoteFragmentSpecExample.my_function_greeter(1)
      end)
    end
  end
end
