defmodule Example do
  use TypeCheck

  type myint :: integer()
  type str :: binary

  spec foo(myint) :: str
  def foo(x) do
    to_string(x)
  end
end
