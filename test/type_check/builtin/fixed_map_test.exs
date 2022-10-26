defmodule TypeCheck.Builtin.FixedMapTest do
  use ExUnit.Case, async: true
  use TypeCheck

  defmodule UnrelatedStruct do
    defstruct []
  end

  defmodule TestStruct do
    defstruct [:value]

    use TypeCheck

    @type! t :: %__MODULE__{
             value: String.t()
           }
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

  test "returns :ok tuple for conforming maps" do
    assert {:ok, _} =
             TypeCheck.conforms(
               %{s: "a-string", i: 45, struct: %TestStruct{value: "a-string"}},
               %{s: String.t(), i: integer(), struct: TestStruct.t()}
             )
  end

  test "returns error for maps with superflous keys" do
    assert {:error, %TypeCheck.TypeError{raw: {_, :superfluous_keys, %{keys: [:foo]}, _}}} =
             TypeCheck.conforms(%{foo: "bar", key: "hello"}, %{key: String.t()})
  end

  test "Checkings structs does not get a 'protocol Enumerable not implemented' (Regression #161)" do
    assert EnumerableNotImplementedExample.hello(%{"a" => :b}) == :ok

    assert EnumerableNotImplementedExample.hello(%EnumerableNotImplementedExample{name: "X"}) ==
             :ok
  end
end
