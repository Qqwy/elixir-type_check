defmodule TypeCheck.MacrosTest do
  use ExUnit.Case, async: true
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

    # We cheat a little here;
    # This is an alternative simplified implementation of `IEx.Helpers.t`
    # Which only works for this particular example.
    # c.f. https://github.com/elixir-lang/elixir/blob/c31c79f8f8df27b8eaeb01365dd7eb64f5e1f347/lib/iex/lib/iex/introspection.ex#L650
    def t(module) do
      {:ok, [type: type]} = Code.Typespec.fetch_types(module)

      "@type " <>
        (type
         |> Code.Typespec.type_to_quoted()
         |> Macro.to_string())
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
      assert TypeCheck.Type.type?(BasicTypeDefinition.mylist())
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

  test "specs can be added to private functions" do
    defmodule PrivateFunctionSpecExample do
      use TypeCheck

      @spec! secret(integer()) :: integer()
      defp secret(_), do: 42

      def public(val) do
        secret(val)
      end
    end

    assert TypeCheck.Spec.defined?(PrivateFunctionSpecExample, :secret, 1)
    assert [secret: 1] == PrivateFunctionSpecExample.__type_check__(:specs)

    # importantly, {secret: 1} is not in there:
    assert ["__TypeCheck spec for 'secret/1'__": 0, __type_check__: 1, public: 1] =
             PrivateFunctionSpecExample.__info__(:functions)

    assert PrivateFunctionSpecExample.public(10) == 42

    assert_raise(TypeCheck.TypeError, fn ->
      PrivateFunctionSpecExample.public("not an integer")
    end)
  end

  test "specs can be added to macros" do
    defmodule MacroSpecExample do
      use TypeCheck

      @spec! compile_time_atom_to_string(atom()) :: String.t()
      defmacro compile_time_atom_to_string(atom) do
        to_string(atom)
      end
    end

    defmodule Example do
      require MacroSpecExample

      def example do
        MacroSpecExample.compile_time_atom_to_string(:baz)
      end
    end

    assert_raise(TypeCheck.TypeError, fn ->
      defmodule Example2 do
        require MacroSpecExample

        def example do
          MacroSpecExample.compile_time_atom_to_string(42)
        end
      end
    end)
  end

  test "__MODULE__ is expanded correctly" do
    defmodule ModuleExpansion do
      use TypeCheck

      defstruct [:name]
      @type! t :: %__MODULE__{name: String.t()}

      @spec! build(String.t()) :: t()
      def build(name) do
        %__MODULE__{name: name}
      end
    end

    assert ModuleExpansion.build("hello") == %{__struct__: ModuleExpansion, name: "hello"}

    assert_raise TypeCheck.TypeError, fn ->
      ModuleExpansion.build(:not_a_string)
    end
  end

  test "Using a struct-type before `defstruct` fails with a descriptive CompileError" do
    assert_raise(
      CompileError,
      ~r"Could not look up default fields for struct type",
      fn ->
        defmodule Problematic do
          use TypeCheck

          @type! t :: %__MODULE__{name: String.t()}
          defstruct [:name]
        end
      end
    )
  end

  test "Specs for struct types don't truncate fields (regression-test for https://github.com/Qqwy/elixir-type_check/issues/78)" do
    defmodule DontTruncate do
      use TypeCheck

      defstruct name: "Foo", age: 42

      @spec! from_map(%{optional(atom()) => any()}) :: %__MODULE__{}
      def from_map(map) do
        struct(__MODULE__, map)
      end
    end

    res = DontTruncate.from_map(%{name: "asdf", age: 33})
    assert struct(DontTruncate, %{name: "asdf", age: 33}) == res
  end
end
