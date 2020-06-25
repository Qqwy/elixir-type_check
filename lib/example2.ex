defmodule Example2 do
  use TypeCheck
  require TypeCheck.Builtin


  type mylist :: list(integer())
  type mylist2 :: list(integer)
  type mylist3(a) :: list(a)
  type mylist4 :: mylist2
  type mylist5 :: mylist3(integer())
  type integer() :: 42
  type foo :: integer()

  def example do
    {mylist(), mylist2(), mylist3(10), mylist3(TypeCheck.Builtin.integer()), integer()}
    # {mylist(), mylist2(), mylist3(10), mylist3(mylist3(integer()))}
  end
end
