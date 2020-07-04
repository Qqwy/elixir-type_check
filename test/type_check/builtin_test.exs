defmodule TypeCheck.BuiltinTest do
  use ExUnit.Case
  use ExUnitProperties
  import StreamData, only: []

  require TypeCheck
  import TypeCheck.Builtin

  doctest TypeCheck.Builtin
end
