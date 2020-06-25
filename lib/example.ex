defmodule Example do
  use TypeCheck

  type myint :: integer()
  type str :: binary
  type myint2 :: myint
  type num :: integer() | float()
  type one :: 1

  type char :: 0..255
  type literal_range :: literal(0..255)

  type result :: :ok | :error | unknown

  spec foo(myint) :: str
  def foo(x) do
    to_string(x)
  end
end
