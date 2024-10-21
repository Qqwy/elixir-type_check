defmodule TypeCheck.Builtin.FunctionTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import StreamData, only: []
  use TypeCheck

  test "Recognizes arity-0 function syntax" do
    function_type = TypeCheck.Type.build((-> integer()))
    assert inspect(function_type) == "#TypeCheck.Type< ( -> integer()) >"
  end

  test "Recognizes any-arity function syntax" do
    function_type = TypeCheck.Type.build((... -> integer()))
    assert inspect(function_type) == "#TypeCheck.Type< (... -> integer()) >"
  end

  test "Recognizes function syntax with parameter types" do
    function_type = TypeCheck.Type.build((boolean(), binary() -> integer()))
    assert inspect(function_type) == "#TypeCheck.Type< (boolean(), binary() -> integer()) >"
  end

  property "Raises on input which is not a function" do
    check all input <- StreamData.term(),
              not is_function(input) do
      {:error, problem} = TypeCheck.conforms(input, (boolean(), binary() -> integer()))
      assert {_, :no_match, _, ^input} = problem.raw
    end
  end

  property "Functions of correct arity are OK, but will raise when called with incorrect input later" do
    check all input <- StreamData.term(),
              not is_integer(input) do
      myfun = fn condition, thing ->
        if condition do
          thing
        else
          42
        end
      end

      assert {:ok, fun} = TypeCheck.conforms(myfun, (boolean(), binary() -> integer()))

      assert fun.(false, "asdf") == 42

      exception =
        assert_raise(TypeCheck.TypeError, fn ->
          fun.(:not_a_boolean, "asdf")
        end)

      assert {_, :param_error, %{index: 0}, _} = exception.raw

      exception =
        assert_raise(TypeCheck.TypeError, fn ->
          fun.(true, 12345)
        end)

      assert {_, :param_error, %{index: 1}, _} = exception.raw

      # Return type
      exception =
        assert_raise(TypeCheck.TypeError, fn ->
          fun.(true, "asdf")
        end)

      assert {_, :return_error, _, _} = exception.raw
    end
  end

  describe "property testing generation" do
    test "function generators' generated funs generate different results" do
      function_type = TypeCheck.Type.build((integer() -> String.t()))
      funs = TypeCheck.Type.StreamData.to_gen(function_type) |> Enum.take(100)

      results =
        funs
        |> Enum.map(fn fun -> fun.(42) end)
        |> MapSet.new()

      assert MapSet.size(results) > 1
    end

    test "function generators are pure" do
      function_type = TypeCheck.Type.build((integer() -> String.t()))
      funs = TypeCheck.Type.StreamData.to_gen(function_type) |> Enum.take(100)
      first_calls = Enum.map(funs, fn fun -> fun.(42) end)
      second_calls = Enum.map(funs, fn fun -> fun.(42) end)
      assert first_calls == second_calls
    end
  end
end
