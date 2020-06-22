defmodule Example do
  use TypeCheck

  type myint :: integer()
  type str :: binary
  type myint2 :: myint
  type num :: integer() | float()

  spec foo(myint) :: str
  def foo(x) do
    to_string(x)
  end
end
