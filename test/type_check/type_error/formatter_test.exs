defmodule TypeCheck.TypeError.FormatterTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []

  import TypeCheck.Type.StreamData

  for module <- [
        # TypeCheck.Builtin.Any,
        TypeCheck.Builtin.Atom,
        TypeCheck.Builtin.Binary,
        TypeCheck.Builtin.Bitstring,
        TypeCheck.Builtin.Boolean,
        TypeCheck.Builtin.CompoundFixedMap,
        TypeCheck.Builtin.FixedList,
        TypeCheck.Builtin.FixedMap,
        TypeCheck.Builtin.FixedTuple,
        TypeCheck.Builtin.Float,
        TypeCheck.Builtin.Function,
        # TypeCheck.Builtin.Guarded,
        TypeCheck.Builtin.ImplementsProtocol,
        TypeCheck.Builtin.Integer,
        TypeCheck.Builtin.Lazy,
        TypeCheck.Builtin.List,
        TypeCheck.Builtin.Literal,
        TypeCheck.Builtin.Map,
        TypeCheck.Builtin.MaybeImproperList,
        TypeCheck.Builtin.NamedType,
        TypeCheck.Builtin.NegInteger,
        TypeCheck.Builtin.None,
        TypeCheck.Builtin.NonNegInteger,
        TypeCheck.Builtin.Number,
        TypeCheck.Builtin.OneOf,
        # TypeCheck.Builtin.Pid,
        TypeCheck.Builtin.Port,
        TypeCheck.Builtin.PosInteger,
        TypeCheck.Builtin.Range,
        TypeCheck.Builtin.Reference,
        # TypeCheck.Builtin.SizedBitstring,
        TypeCheck.Builtin.Tuple
      ] do
    property "the default formatter is able to handle all problem tuples (returning a binary string message) of type #{module}" do
      check all problem <-
                  StreamData.scale(
                    to_gen(unquote(module).problem_tuple()),
                    &div(&1, 3)
                  ) do
        result = TypeCheck.TypeError.DefaultFormatter.format(problem)
        assert is_binary(result)
      end
    end
  end

  property "the default formatter is able to handle all problem tuples (returning a binary string message)" do
    check all problem <-
                StreamData.scale(
                  to_gen(TypeCheck.TypeError.Formatter.problem_tuple()),
                  &div(&1, 3)
                ) do
      result = TypeCheck.TypeError.DefaultFormatter.format(problem)
      assert is_binary(result)
    end
  end
end
