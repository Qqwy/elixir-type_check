defmodule TypeCheck.TypeTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []

  require TypeCheck.Type
  import TypeCheck.Builtin

  doctest TypeCheck.Type

  doctest TypeCheck.Type.StreamData
end
