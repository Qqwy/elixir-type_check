defmodule TypeCheck.BuiltinTest do
  use ExUnit.Case, async: true
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
        fixed_list([1, 2])
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
        [integer()]
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
      end => TypeCheck.Builtin.NamedType,
      quote do
        impl(Enumerable)
      end => TypeCheck.Builtin.ImplementsProtocol,
      quote do
        <<_ :: 4 >>
      end => TypeCheck.Builtin.SizedBitstring,
    }

    for {type, module} <- possibilities do
      property "for type `#{Macro.to_string(type)}`" do
        check all input <- StreamData.term() do
          # We special-case 'Any' and 'None'
          # as they otherwise trigger "this clause cannot match because of different types/sizes"-warnings.
          case unquote(module) do
            TypeCheck.Builtin.Any ->
              # Should _always_ match
              assert {:ok, _} = TypeCheck.conforms(input, unquote(type))
            TypeCheck.Builtin.None ->
              # Should _never_ match
              assert {:error, _} = TypeCheck.conforms(input, unquote(type))
            _other ->
              # Matches sometimes.

              case TypeCheck.conforms(input, unquote(type)) do
                {:ok, _} ->
                  :ok

                {:error, problem = %TypeCheck.TypeError{}} ->
                  IO.inspect(problem.raw, label: :raw_problem)
                  IO.inspect(unquote(module).problem_tuple(), structs: false, label: :raw_problem_tuple)
                  TypeCheck.conforms!(problem.raw, unquote(module).problem_tuple())
              end
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

      unless module in [TypeCheck.Builtin.None] do
        property "#{module}'s ToStreamData implementation conforms with its own type" do
          require TypeCheck.Type
          check all value <- TypeCheck.Protocols.ToStreamData.to_gen(TypeCheck.Type.build(unquote(type))) do
            assert {:ok, _} = TypeCheck.conforms(value, unquote(type))
          end
        end
      end
    end
  end

  test "none() and any() are opposites" do
    assert {:ok, _} = TypeCheck.conforms(none(), any())
    assert {:error, _} = TypeCheck.conforms(any(), none())
  end
end
