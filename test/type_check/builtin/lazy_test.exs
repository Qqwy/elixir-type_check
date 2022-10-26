defmodule TypeCheck.Builtin.LazyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []
  import TypeCheck.Builtin
  require TypeCheck.Type

  test "Inspect implementation is sensible" do
    res = inspect(TypeCheck.Type.build(lazy(1..5)))

    if Version.compare(System.version(), "1.12.0") == :lt do
      assert res == "#TypeCheck.Type< lazy(TypeCheck.Builtin.range(%Range{first: 1, last: 5}) >"
    else
      assert res ==
               "#TypeCheck.Type< lazy(TypeCheck.Builtin.range(%Range{first: 1, last: 5, step: 1}) >"
    end

    res = inspect(TypeCheck.Type.build(lazy(42)))
    assert res == "#TypeCheck.Type< lazy(TypeCheck.Builtin.literal(42) >"
  end
end
