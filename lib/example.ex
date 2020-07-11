defmodule Example do
  use TypeCheck
  import Kernel, except: [@: 1]
  require TypeCheck.Macros
  import TypeCheck.Macros, only: [@: 1]

  @type myint :: integer()

  @doc "Does this documentation show up?"
  @spec add(integer(), integer()) :: myint()
  def add(a, b) do
    a + b
  end
end
