defmodule TypeCheck.Builtin.LazyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []
  import TypeCheck.Builtin
  require TypeCheck.Type

  test "Inspect implementation is sensible" do
    res = inspect(TypeCheck.Type.build(lazy(1..5)))
    assert res == "#TypeCheck.Type< lazy(TypeCheck.Builtin.range(%Range{first: 1, last: 5, step: 1}) >"

    res = inspect(TypeCheck.Type.build(lazy(42)))
    assert res == "#TypeCheck.Type< lazy(TypeCheck.Builtin.literal(42) >"
  end

end
