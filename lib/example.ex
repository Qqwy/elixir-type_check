defmodule Example do
  use TypeCheck

  type myint :: integer()

  @doc "Does this documentation show up?"
  spec add(integer(), integer()) :: myint()
  def add(a, b) do
    a + b
  end
end
