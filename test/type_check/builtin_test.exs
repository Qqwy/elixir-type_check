defmodule TypeCheck.BuiltinTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []

  require TypeCheck
  import TypeCheck.Builtin

  doctest TypeCheck.Builtin

  describe "builtin types adhere to their problem_tuple result types." do
    possibilities = %{
      quote do
        any()
      end => TypeCheck.Builtin.Any,
      quote do
        atom()
      end => TypeCheck.Builtin.Atom,
      quote do
        binary()
      end => TypeCheck.Builtin.Binary,
      quote do
        bitstring()
      end => TypeCheck.Builtin.Bitstring,
      quote do
        boolean()
      end => TypeCheck.Builtin.Boolean,
      quote do
        float()
      end => TypeCheck.Builtin.Float,
      quote do
        [1, 2]
      end => TypeCheck.Builtin.FixedList,
      quote do
        %{a: 1, b: integer()}
      end => TypeCheck.Builtin.FixedMap,
      quote do
        {1, float()}
      end => TypeCheck.Builtin.FixedTuple,
      quote do
        integer()
      end => TypeCheck.Builtin.Integer,
      quote do
        pos_integer()
      end => TypeCheck.Builtin.PosInteger,
      quote do
        neg_integer()
      end => TypeCheck.Builtin.NegInteger,
      quote do
        non_neg_integer()
      end => TypeCheck.Builtin.NonNegInteger,
      quote do
        map(atom(), any())
      end => TypeCheck.Builtin.Map,
      quote do
        list()
      end => TypeCheck.Builtin.List,
      quote do
        literal(42)
      end => TypeCheck.Builtin.Literal,
      quote do
        range(0, 1000)
      end => TypeCheck.Builtin.Range,
      quote do
        tuple()
      end => TypeCheck.Builtin.Tuple,
      quote do
        number()
      end => TypeCheck.Builtin.Number,
      quote do
        none()
      end => TypeCheck.Builtin.None,
      quote do
        x :: integer()
      end => TypeCheck.Builtin.NamedType
    }

    for {type, module} <- possibilities do
      property "for type `#{Macro.to_string(type)}`" do
        check all input <- StreamData.term() do
          case TypeCheck.conforms(input, unquote(type)) do
            {:ok, _} ->
              :ok

            {:error, problem = %TypeCheck.TypeError{}} ->
              TypeCheck.conforms!(problem.raw, unquote(module).problem_tuple())
          end
        end
      end

      test "#{module} Dogfoods by using TypeCheck itself" do
        internal_module = Module.concat(TypeCheck.Internals.UserTypes, unquote(module))
        assert Code.ensure_loaded?(internal_module)
        assert TypeCheck.Type.type?(apply(internal_module, :problem_tuple, []))
      end

      test "#{Macro.to_string(type)} has a proper implementation of the Inspect protocol" do
        require TypeCheck.Type
        str = inspect(TypeCheck.Type.build(unquote(type)))
        assert is_binary(str)
        assert str =~ ~r{^#TypeCheck.Type< }
        assert str =~ ~r{ >$}
      end
    end
  end
end
