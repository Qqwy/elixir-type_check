defmodule TypeCheck.MacrosTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []
  import TypeCheck.Type.StreamData


  describe "doctests" do
    # Required for the unquote fragments example in the moduledoc:
    defmodule MetaExample do
      use TypeCheck
      people = ~w[joe robert mike]a
      for name <- people do
        @type! unquote(name)() :: %{name: unquote(name), coolness_level: :high}
      end
    end


    # Required for the macro example in the moduledoc:
    defmodule GreeterMacro do
      defmacro generate_greeter(greeting) do
        import Kernel, except: [@: 1]
        quote bind_quoted: [greeting: greeting] do
          @spec! unquote(greeting)(binary) :: binary
          def unquote(greeting)(name) do
            "#{unquote(greeting)}, #{name}!"
          end
        end
      end
    end

    defmodule GreeterExample do
      use TypeCheck
      require GreeterMacro

      GreeterMacro.generate_greeter(:hi)
      GreeterMacro.generate_greeter(:hello)
    end

    doctest TypeCheck.Macros
  end


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
          import Kernel, except: [@: 1]
          quote bind_quoted: [name: name], location: :keep do
            @spec! unquote(:"my_function_#{name}")(binary) :: binary
            def unquote(:"my_function_#{name}")(greeting) do
              greeting
            end
          end
        end
      end

      defmodule UnquoteFragmentSpecExample do
        use TypeCheck
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
