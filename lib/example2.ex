defmodule Example2 do
  use TypeCheck


  type mylist :: list(integer())
  type mylist2 :: list(integer)
  type mylist3(a) :: list(a)
  type mylist4 :: mylist2
  type mylist5 :: mylist3(integer())

  def example do
    :ok
    # {mylist(), mylist2(), mylist3(10), mylist3(TypeCheck.Builtin.integer())}
    # {mylist(), mylist2(), mylist3(10), mylist3(mylist3(integer()))}
  end

  spec wrap(list()) :: any() # list(integer())
  def wrap(int) do
    [int, int]
  end


  spec wrap(integer(), integer()) :: list(integer())
  def wrap(int1, int2) do
    [int1, int2]
  end

  spec listwrap(list(integer())) :: any()
  def listwrap(list) do
    {:ok, list}
  end
end
