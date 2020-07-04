defmodule Example4 do
  use TypeCheck

  ## The following is an example
  ## of a mutually-recursive type
  ## that will currently make TypeCheck hang
  # type empty :: nil
  # type cons(a) :: {a, lazy(mylist(a))}
  # type mylist(a) :: empty() | cons(a)

  # spec new_list() :: mylist(any())
  # def new_list() do
  #   nil
  # end

  # spec cons_val(mylist(any()), any()) :: mylist(any)
  # def cons_val(list, val) do
  #   {val, list}
  # end
end
