defmodule TypeCheck.TypeTest do
  use ExUnit.Case
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
end
