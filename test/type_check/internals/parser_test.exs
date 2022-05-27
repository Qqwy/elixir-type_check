defmodule TypeCheck.Internals.ParserTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest TypeCheck.Internals.Parser

  alias TypeCheck.Internals.Parser
  alias TypeCheck.Builtin, as: B

  alias TypeCheck.Internals.ParserTest.TypespecSample

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
      {Kernel, :div, 2, [B.integer(), B.one_of(B.neg_integer(), B.pos_integer())], B.integer()},
      {Kernel, :elem, 2, [B.tuple(), B.non_neg_integer()], B.term()},
      {Kernel, :hd, 1, [B.nonempty_list(B.any())], B.any()},
      {Kernel, :is_atom, 1, [B.term()], B.boolean()},
      # TODO(@orsinium): update when reference and port are supported
      {Kernel, :node, 1, [B.one_of([B.pid(), B.any(), B.any()])], B.atom()},
      {Kernel, :tl, 1, [B.nonempty_list()], B.one_of(B.list(), B.any())},
      {Kernel, :tuple_size, 1, [B.tuple()], B.non_neg_integer()},
      {Kernel, :apply, 2, [B.fun(), B.list()], B.any()},
      {Kernel, :apply, 3, [B.module(), B.atom(), B.list()], B.any()},
      {Kernel, :exit, 1, [B.term()], B.none()},
      {Kernel, :function_exported?, 3, [B.module(), B.atom(), B.arity()], B.boolean()},
      {Kernel, :get_in, 2, [B.any(), B.nonempty_list(B.term())], B.term()},
      {Kernel, :max, 2, [B.term(), B.term()], B.one_of([B.term(), B.term()])},
      {Enum, :all?, 2, [B.any(), B.function([B.any()], B.as_boolean(B.term()))], B.boolean()},
      {Macro, :var, 2, [B.atom(), B.atom()], B.fixed_tuple([B.atom(), B.any(), B.atom()])}
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

  defmacrop test_module(raw_spec) do
    quote do
      {:module, _, bytecode, _} =
        defmodule TypespecSample do
          @moduledoc false
          @spec f(any) :: unquote(raw_spec)
          def f(a), do: a
        end

      :code.delete(TypespecSample)
      :code.purge(TypespecSample)
      bytecode
    end
  end

  def convert_spec(bytecode) do
    {:ok, spec} = bytecode |> Parser.fetch_spec(:f, 1)
    # IO.inspect(spec)
    %TypeCheck.Builtin.Function{return_type: t} = Parser.convert(spec)
    t
  end

  describe "convert custom" do
    test "any" do
      bytecode = test_module(any)
      assert convert_spec(bytecode) == B.any()
    end

    test "atom" do
      bytecode = test_module(atom)
      assert convert_spec(bytecode) == B.atom()
    end

    test "term" do
      bytecode = test_module(term)
      assert convert_spec(bytecode) == B.term()
    end

    test "module" do
      bytecode = test_module(module)
      assert convert_spec(bytecode) == B.module()
    end

    test "as_boolean" do
      bytecode = test_module(as_boolean(atom()))
      assert convert_spec(bytecode) == B.as_boolean(B.atom())
    end

    test "arity" do
      bytecode = test_module(arity)
      assert convert_spec(bytecode) == B.arity()
    end

    test "binary" do
      bytecode = test_module(binary)
      assert convert_spec(bytecode) == B.binary()
    end

    test "nonempty_binary" do
      bytecode = test_module(<<_::8, _::_*8>>)
      assert convert_spec(bytecode) == B.nonempty_binary()
    end

    test "empty bitstring" do
      bytecode = test_module(<<>>)
      assert convert_spec(bytecode) == B.sized_bitstring(0)
    end

    test "sized_bitstring/1" do
      bytecode = test_module(<<_::16>>)
      assert convert_spec(bytecode) == B.sized_bitstring(16)
    end

    test "boolean" do
      bytecode = test_module(boolean)
      assert convert_spec(bytecode) == B.boolean()
    end

    test "byte" do
      bytecode = test_module(byte)
      assert convert_spec(bytecode) == B.byte()
    end

    test "char" do
      bytecode = test_module(char)
      assert convert_spec(bytecode) == B.char()
    end

    test "charlist" do
      bytecode = test_module(charlist)
      assert convert_spec(bytecode) == B.charlist()
    end
  end
end
