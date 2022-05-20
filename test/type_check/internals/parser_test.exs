defmodule TypeCheck.Internals.ParserTest do
  use ExUnit.Case, async: true

  alias TypeCheck.Internals.Parser

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
end
