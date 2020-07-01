defmodule Example do
  use TypeCheck
  import TypeCheck.Builtin

  # type literal(t) :: t

  type myint :: integer()
  type myint2 :: myint()
  type num :: integer() | float()
  type one :: 1

  # type char :: 0..255
  # type literal_range :: literal(0..255)
  type foo :: literal(10)

  type result :: :ok | :error | any()

  type example :: tuple(3)

  type z :: tuple_of([3, 4, 5])

  type blar :: map(atom(), integer())
  type blaz :: fixed_map(a: integer(), b: float(), c: blar())

  type sorted_pair(a, b) :: {first :: a, second :: b} when first <= second

  # spec foo(integer()) :: float()
  def foo(x) do
    x + 0.0
  end
end

