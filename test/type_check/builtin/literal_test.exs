defmodule TypeCheck.Builtin.LiteralTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []
  import TypeCheck.Builtin
  require TypeCheck.Type

  test "inspects literal range-structs correctly" do
    res = inspect(TypeCheck.Type.build(literal(1..5)))
    assert "#TypeCheck.Type< literal( 1..5 ) >" == res
  end
end
