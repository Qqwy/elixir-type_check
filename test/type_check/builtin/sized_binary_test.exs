defmodule TypeCheck.Builtin.SizedBitstringTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []
  use TypeCheck

  test "Recognizes empty <<>> as literal empty binary" do
    t = TypeCheck.Type.build(<<>>)
    assert %TypeCheck.Builtin.Literal{value: <<>>} = t
  end

  property "Handles any sized bitstring (with only a prefix size) correctly" do
    check all prefix_size <- StreamData.positive_integer(),
      str <- StreamData.bitstring(length: prefix_size),
      wrong_str <- StreamData.bitstring(length: prefix_size + 1) do
      t = TypeCheck.Builtin.sized_bitstring(prefix_size)
      assert %TypeCheck.Builtin.SizedBitstring{prefix_size: ^prefix_size} = t

      assert {:ok, ^str} = TypeCheck.dynamic_conforms(str, t)
      assert {:error, %{raw: {_, :no_match, _, _}}} = TypeCheck.dynamic_conforms(42, t)
      assert {:error, %{raw: {_, :wrong_size, _, _}}} = TypeCheck.dynamic_conforms(wrong_str, t)
    end
  end

  property "Handles any sized bitstring (with only a unit size) correctly" do
    check all unit_size <- StreamData.integer(1..256),
      repetitions <- StreamData.positive_integer(),
      str <- StreamData.bitstring(length: repetitions * unit_size),
      wrong_str <- StreamData.bitstring(length: repetitions * unit_size + 1) do
      t = TypeCheck.Builtin.sized_bitstring(0, unit_size)
      assert %TypeCheck.Builtin.SizedBitstring{prefix_size: 0, unit_size: ^unit_size} = t

      assert {:ok, ^str} = TypeCheck.dynamic_conforms(str, t)
      assert {:error, %{raw: {_, :no_match, _, _}}} = TypeCheck.dynamic_conforms(42, t)
      if unit_size > 1 do
        assert {:error, %{raw: {_, :wrong_size, _, _}}} = TypeCheck.dynamic_conforms(wrong_str, t)
      end
    end
  end

  property "Handles any sized bitstring (with both a prefix size and a unit size) correctly" do
    check all prefix_size  <- StreamData.positive_integer(),
              unit_size    <- StreamData.integer(1..256),
              repetitions  <- StreamData.positive_integer(),
              proper_length = prefix_size + repetitions * unit_size,
              wrong_length = proper_length + 1,
              str          <- StreamData.bitstring(length: proper_length),
              wrong_str    <- StreamData.bitstring(length: wrong_length) do

      t = TypeCheck.Builtin.sized_bitstring(prefix_size, unit_size)
      assert %TypeCheck.Builtin.SizedBitstring{prefix_size: ^prefix_size, unit_size: ^unit_size} = t

      assert {:ok, ^str} = TypeCheck.dynamic_conforms(str, t)
      assert {:error, %{raw: {_, :no_match, _, _}}} = TypeCheck.dynamic_conforms(42, t)
      if unit_size > 1 do
        assert {:error, %{raw: {_, :wrong_size, _, _}}} = TypeCheck.dynamic_conforms(wrong_str, t)
      end
    end
  end
end
