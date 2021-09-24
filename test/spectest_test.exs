defmodule SpectestTest do
  use ExUnit.Case, async: true
  import TypeCheck.ExUnit

  spectest DebugExample
end
