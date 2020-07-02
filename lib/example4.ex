defmodule Example4 do
  use TypeCheck

  ## The following is an example
  ## of a mutually-recursive type
  ## that will currently make TypeCheck hang
  type empty :: nil
  type cons() :: {integer(), lazy(mylist())}
  type mylist() :: empty() | lazy(cons())

  spec new_list() :: mylist()
  def new_list() do
    nil
  end

  spec cons_val(mylist(), integer()) :: mylist()
  def cons_val(list, val) do
    {val, list}
  end

  # spec foo(lazy(integer())) :: boolean()
  # def foo(x) do
  #   x > 0
  # end
end
