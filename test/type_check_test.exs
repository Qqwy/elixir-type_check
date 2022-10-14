defmodule TypeCheckTest.TypeGuardExample do
  use TypeCheck
  @type! sorted_pair :: {lower :: number(), higher :: number()} when lower <= higher
end

defmodule TypeCheckTest.SpecWithGuardExample do
  use TypeCheck
  @spec! in_magic_range(x :: non_neg_integer() when x != 42) :: boolean()
  def in_magic_range(_val) do
    true
  end
end

defmodule TypeCheckTest.TypeWithGuardExample do
  use TypeCheck
  @type! magic_num :: non_neg_integer() when magic_num != 69
end

defmodule TypeCheckTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import TypeCheckTest.TypeGuardExample

  require TypeCheck.Type
  doctest TypeCheck

  # property "the different confrorm variants have the same results" do
  #   check all value <- term(),
  #             !is_reference(value),
  #             type <- TypeCheck.Type.StreamData.arbitrary_type_gen() do
  #     # res1 = TypeCheck.conforms(value, type)
  #     # res2 = TypeCheck.conforms?(value, type)
  #     # res3 =
  #     #   try do
  #     #     TypeCheck.conforms!(value, type)
  #     #     {:ok, value}
  #     #   rescue
  #     #     e = TypeCheck.TypeError ->
  #     #       {:error, e}
  #     #   end

  #     res4 = TypeCheck.dynamic_conforms(value, type)
  #     res5 = TypeCheck.dynamic_conforms?(value, type)
  #     res6 =
  #       try do
  #         TypeCheck.dynamic_conforms!(value, type)
  #         value
  #       rescue
  #         e ->
  #           e
  #       end
  #     case res4 do
  #       {:ok, val} ->
  #         assert res5 == true
  #         assert res6 == val
  #       {:error, problem} ->
  #         assert res5 == false
  #         assert res6 == problem
  #     end
  #   end
  # end

  describe "spec with guard" do
    test "it is callable" do
      assert TypeCheckTest.SpecWithGuardExample.in_magic_range(10) == true
    end

    test "it will raise when the input does not match the spec type" do
      exception =
        assert_raise(TypeCheck.TypeError, fn ->
          TypeCheckTest.SpecWithGuardExample.in_magic_range(-10)
        end)

      assert {%TypeCheck.Spec{}, :param_error, %{}, [-10]} = exception.raw

      assert {%TypeCheck.Builtin.Guarded{}, :type_failed, %{}, -10} =
               elem(exception.raw, 2).problem
    end

    test "it will raise when the input does not match the spec guard" do
      exception =
        assert_raise(TypeCheck.TypeError, fn ->
          TypeCheckTest.SpecWithGuardExample.in_magic_range(42)
        end)

      assert {%TypeCheck.Spec{}, :param_error, %{}, [42]} = exception.raw

      assert {%TypeCheck.Builtin.Guarded{}, :guard_failed, %{}, 42} =
               elem(exception.raw, 2).problem
    end
  end

  describe "type with guard" do
    test "it can be conformed against" do
      require TypeCheck
      assert TypeCheck.conforms?(10, TypeCheckTest.TypeWithGuardExample.magic_num())
      refute TypeCheck.conforms?(69, TypeCheckTest.TypeWithGuardExample.magic_num())
    end
  end

  test "StreamData is optional" do
    {stdout, 0} =
      System.cmd("mix", ["deps.compile", "--force"],
        cd: "./test/support/depending_project",
        stderr_to_stdout: true
      )

    refute stdout =~ "warning: StreamData"
    refute stdout =~ "warning: "
  end

  describe "Typespec generation" do
    test "Typespec generation of recursive type (using lazy) with one_of works (regression test for #139)" do
      # Depends on the example in `support/typespec_generation_example.ex`
      {:ok, [type: t1, type: t2]} = Code.Typespec.fetch_types(TypespecGenerationExample)
      t1_str = t1 |> Code.Typespec.type_to_quoted() |> Macro.to_string()
      t2_str = t2 |> Code.Typespec.type_to_quoted() |> Macro.to_string()

      assert t1_str == "t(value) :: {:value, value} | {:t, t()}"
      assert t2_str == "t() :: t(true | false)"
    end
  end

  test "Using the qualified name of a type inside a module defining it is possible (regression test for #154)" do
    assert TypeCheck.conforms?(%QualifiedNamesExample{name: "Battler"}, QualifiedNamesExample.t())
  end
end
