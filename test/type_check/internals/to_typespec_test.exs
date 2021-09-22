defmodule TypeCheck.Internals.ToTypespecTest do
  use ExUnit.Case

  test "Generates typespecs which Elixir can indeed parse" do
    defmodule Example do
      use TypeCheck
      @type! laziness :: lazy(integer())

      @type! guarded :: integer() when rem(guarded, 2) == 0

      @type! named :: named_type(:mycooltype, integer())

      @type! possibilities :: one_of([integer(), atom()])

      @type! mytuple :: fixed_tuple([atom(), integer()])

      @type! triple :: tuple(3)

      @type! myfixedlist :: fixed_list([atom(), integer()])

      @type! myrange :: range(1..10)

      @type! myliteral :: literal(42)
    end
  end
end
