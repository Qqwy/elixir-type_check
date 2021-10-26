defmodule TypeCheck.Builtin.FixedMapTest do
  use ExUnit.Case, async: true
  use TypeCheck

  defmodule UnrelatedStruct do
    defstruct []
  end

  # Regression test for issue #74
  test "Date.t() only accepts valid dates" do
    fun = &TypeCheck.conforms(&1, Date.t())


    assert {:ok, _} = fun.(Date.utc_today())

    assert {:error, _} = fun.(DateTime.utc_now())
    assert {:error, _} = fun.(%{})
    assert {:error, _} = fun.(%UnrelatedStruct{})

    assert {:error, _} = fun.([])
    assert {:error, _} = fun.(6)
    assert {:error, _} = fun.("some string")
  end

end
