defmodule TypeCheck.Builtin.NamedTypeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []
  use TypeCheck

  # defmodule Example do
  #   use TypeCheck, debug: true

  #   @opaque! secret() :: fancy :: binary()
  #   @type! known :: (foo :: %{a: number(), b: secret()} when is_map(fancy))

  #   @spec! foo() :: known()
  #   def foo() do
  #   end
  # end
end
