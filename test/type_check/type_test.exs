defmodule TypeCheck.TypeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []

  require TypeCheck.Type
  import TypeCheck.Builtin

  doctest TypeCheck.Type

  doctest TypeCheck.Type.StreamData

  test "check whether we can print a type built from a Stream struct" do
    # c.f. https://github.com/Qqwy/elixir-type_check/issues/45
    stream_type_string =  TypeCheck.Type.build(%Stream{}) |> inspect()
    assert stream_type_string == "#TypeCheck.Type< #Stream<[...]> >"
  end

  test "ensure_type! raises on non-types with a descriptive message" do
    assert_raise(TypeCheck.CompileError, ~r{^Invalid value passed to a function expecting a type!}, fn -> TypeCheck.Type.ensure_type!(42) end)
  end
end
