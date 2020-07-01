defmodule Example2 do
  use TypeCheck
  import TypeCheck.Builtin

  # type integer :: TypeCheck.Builtin.any()
  type mylist :: list(integer())
  type mylist2 :: list(integer())
  type mylist3(a) :: list(a)
  typep mylist4 :: mylist2()
  type mylist5 :: mylist3(integer()) | mylist4()

  def example do
    :ok
    # {mylist(), mylist2(), mylist3(10), mylist3(TypeCheck.Builtin.integer())}
    # {mylist(), mylist2(), mylist3(10), mylist3(mylist3(integer()))}
  end

  spec wrap(mylist()) :: any() # list(integer())
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

  # spec maybe_div(either(integer(), float()), either(integer(), float())) :: either(tuple([literal(:ok), either(integer(), float())]), tuple([literal(:error), atom()]))
  type res :: {:ok, integer() | float()} | {:error, atom()}
  spec maybe_div(integer() | float(), integer() | float()) :: {:ok, integer() | float()} | {:error, atom()}
  # spec maybe_div(integer() | float(), integer() | float()) :: {:ok, integer() | float()}
  def maybe_div(a, b) do
    case {a, b} do
      {_, b} when b == 0 ->
        {:error, :division_by_zero}
      {a, b} when is_integer(a) and is_integer(b) ->
        {:ok, div(a, b)}
      _ ->
        {:ok, a / b}
    end
  end

  spec small(0..500) :: :foo | :bar | :baz
  def small(x) do
    case x do
      x when x in 0..255 -> :ok
      _ -> :error
    end
  end
end
