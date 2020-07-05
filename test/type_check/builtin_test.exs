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
        atom: TypeCheck.Builtin.Atom,
        binary: TypeCheck.Builtin.Binary,
        bitstring: TypeCheck.Builtin.Bitstring,
        float: TypeCheck.Builtin.Float,
        integer: TypeCheck.Builtin.Integer,
        # map: TypeCheck.Builtin.Map,
        # list: TypeCheck.Builtin.List,
        tuple: TypeCheck.Builtin.Tuple,
        number: TypeCheck.Builtin.Number,
      }
    for {type, module} <- possibilities do
      property "#{type}" do
        check all input <- StreamData.term() do
          case TypeCheck.conforms(input, unquote(type)()) do
            {:ok, _} -> :ok
            {:error, problem = %TypeCheck.TypeError{}} ->
              TypeCheck.conforms!(problem.raw, unquote(module).problem_tuple() )
          end
        end
      end
    end
  end
end
