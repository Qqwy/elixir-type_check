defmodule TypeCheck.TypeError.FormatterTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []

  import TypeCheck.Type.StreamData

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
