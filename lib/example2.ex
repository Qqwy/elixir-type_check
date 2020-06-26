defmodule Example2 do
  use TypeCheck
  require TypeCheck.Builtin


  type mylist :: list(integer())
  type mylist2 :: list(integer)
  type mylist3(a) :: list(a)
  type mylist4 :: mylist2
  type mylist5 :: mylist3(integer())

  def example do
    {mylist(), mylist2(), mylist3(10), mylist3(TypeCheck.Builtin.integer())}
    # {mylist(), mylist2(), mylist3(10), mylist3(mylist3(integer()))}
  end

  spec wrap(integer()) :: list(integer())
  def wrap(int) do
    [int, int]
  end


  spec wrap(integer(), integer()) :: list(integer())
  def wrap(int1, int2) do
    [int1, int2]
  end
end
