defmodule Example do
  use TypeCheck

  type myint :: integer()
  type str :: binary
  type myint2 :: myint
  type num :: integer() | float()
  type one :: 1

  type result :: :ok | :error

  spec foo(myint) :: str
  def foo(x) do
    to_string(x)
  end
end
