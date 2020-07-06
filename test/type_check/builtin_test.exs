defmodule TypeCheck.BuiltinTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []

  require TypeCheck
  import TypeCheck.Builtin

  doctest TypeCheck.Builtin


  describe "Checks for builtin types adhere to their problem_tuple result types." do
    possibilities =
      %{
        quote do any() end => TypeCheck.Builtin.Any,
        quote do atom() end => TypeCheck.Builtin.Atom,
        quote do binary() end => TypeCheck.Builtin.Binary,
        quote do bitstring() end => TypeCheck.Builtin.Bitstring,
        quote do boolean() end => TypeCheck.Builtin.Boolean,
        quote do float() end => TypeCheck.Builtin.Float,
        quote do integer() end => TypeCheck.Builtin.Integer,
        quote do map() end => TypeCheck.Builtin.Map,
        quote do list() end => TypeCheck.Builtin.List,
        quote do literal(42) end => TypeCheck.Builtin.Literal,
        quote do range(0, 1000) end => TypeCheck.Builtin.Range,
        quote do tuple() end => TypeCheck.Builtin.Tuple,
        quote do number() end => TypeCheck.Builtin.Number,
      }
    for {type, module} <- possibilities do
      property "#{Macro.to_string(type)}" do
        check all input <- StreamData.term() do
          case TypeCheck.conforms(input, unquote(type)) do
            {:ok, _} -> :ok
            {:error, problem = %TypeCheck.TypeError{}} ->
              TypeCheck.conforms!(problem.raw, unquote(module).problem_tuple() )
          end
        end
      end
    end

    for {type, module} <- possibilities do
      test "#{Macro.to_string(type)} has a proper implementation of the Inspect protocol" do
        str = inspect(unquote(type))
        assert is_binary(str)
        assert str =~ ~r{^#TypeCheck.Type< }
        assert str =~ ~r{ >$}
      end
    end
  end
end
