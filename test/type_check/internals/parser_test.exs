defmodule TypeCheck.Internals.ParserTest do
  use ExUnit.Case, async: true

  alias TypeCheck.Internals.Parser
  alias TypeCheck.Builtin, as: B

  # test that fetch_spec doesn't explode and all specs are supported
  describe "fetch_spec smoke" do
    for module <- [Kernel, String, List, Enum, DateTime] do
      @module module
      for {func, arity} <- module.__info__(:functions) do
        @func func
        @arity arity
        test "#{module}.#{func}/#{arity}" do
          r = Parser.fetch_spec(@module, @func, @arity)
          refute match?({:error, "unsupported spec"}, r)
        end
      end
    end
  end

  # test that for every valid spec convert/1 returns a valid function.
  describe "convert smoke" do
    for module <- [Kernel, String, List, Enum, DateTime] do
      @module module
      for {func, arity} <- module.__info__(:functions) do
        @func func
        @arity arity
        test "#{module}.#{func}/#{arity}" do
          case Parser.fetch_spec(@module, @func, @arity) do
            {:ok, spec} ->
              t = Parser.convert(spec)
              assert %TypeCheck.Builtin.Function{} = t

            {:error, _} ->
              nil
          end
        end
      end
    end
  end

  # test convert using specs of some functions from stdlib
  describe "convert stdlib" do
    cases = [
      {Kernel, :abs, 1, [B.number()], B.number()},
      {Kernel, :binary_part, 3, [B.binary(), B.non_neg_integer(), B.integer()], B.binary()},
      {Kernel, :bit_size, 1, [B.bitstring()], B.non_neg_integer()},
      {Kernel, :ceil, 1, [B.number()], B.integer()},
      {Kernel, :div, 2, [B.integer(), B.one_of([B.neg_integer(), B.pos_integer()])], B.integer()},
      {Kernel, :elem, 2, [B.tuple(), B.non_neg_integer()], B.term()},
      {Kernel, :hd, 1, [B.nonempty_list(B.any())], B.any()},
      {Kernel, :is_atom, 1, [B.term()], B.boolean()},
      # TODO(@orsinium): update when reference and port are supported
      {Kernel, :node, 1, [B.one_of([B.pid(), B.any(), B.any()])], B.atom()},
      {Kernel, :tl, 1, [B.nonempty_list()], B.one_of([B.list(), B.any()])},
      {Kernel, :tuple_size, 1, [B.tuple()], B.non_neg_integer()},
      {Kernel, :apply, 2, [B.fun(), B.list()], B.any()},
      {Kernel, :apply, 3, [B.module(), B.atom(), B.list()], B.any()},
      {Kernel, :exit, 1, [B.term()], B.none()},
      {Kernel, :function_exported?, 3, [B.module(), B.atom(), B.arity()], B.boolean()},
      {Kernel, :get_in, 2, [B.any(), B.nonempty_list(B.term())], B.term()}
    ]

    for {module, func, arity, exp_args, exp_result} <- cases do
      @module module
      @func func
      @arity arity
      @exp_args exp_args
      @exp_result exp_result
      test "#{module}.#{func}/#{arity}" do
        {:ok, spec} = Parser.fetch_spec(@module, @func, @arity)
        exp = B.function(@exp_args, @exp_result)
        assert ^exp = Parser.convert(spec)
      end
    end
  end
end
