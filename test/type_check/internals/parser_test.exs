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
      {Macro, :var, 2, [B.atom(), B.atom()], B.fixed_tuple([B.atom(), B.list(B.any()), B.atom()])}
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

    test "fun" do
      bytecode = test_module(fun)
      assert convert_spec(bytecode) == B.fun()
    end

    test "function/0 (syntax)" do
      bytecode = test_module((... -> any))
      assert convert_spec(bytecode) == B.fun()
    end

    test "function/0" do
      bytecode = test_module(function)
      assert convert_spec(bytecode) == B.function()
    end

    test "function/1" do
      bytecode = test_module((... -> atom()))
      assert convert_spec(bytecode) == B.function(B.atom())
    end

    test "function/2" do
      bytecode = test_module((boolean, integer -> atom))
      assert convert_spec(bytecode) == B.function([B.boolean(), B.integer()], B.atom())
    end

    test "integer" do
      bytecode = test_module(integer)
      assert convert_spec(bytecode) == B.integer()
    end

    test "neg_integer" do
      bytecode = test_module(neg_integer)
      assert convert_spec(bytecode) == B.neg_integer()
    end

    test "non_neg_integer" do
      bytecode = test_module(non_neg_integer)
      assert convert_spec(bytecode) == B.non_neg_integer()
    end

    test "pos_integer" do
      bytecode = test_module(pos_integer)
      assert convert_spec(bytecode) == B.pos_integer()
    end

    test "float" do
      bytecode = test_module(float)
      assert convert_spec(bytecode) == B.float()
    end

    test "number" do
      bytecode = test_module(number)
      assert convert_spec(bytecode) == B.number()
    end

    test "list/0" do
      bytecode = test_module(list)
      assert convert_spec(bytecode) == B.list()
    end

    test "list/0 (syntax)" do
      bytecode = test_module([])
      assert convert_spec(bytecode) == B.list()
    end

    test "list/1" do
      bytecode = test_module(list(integer))
      assert convert_spec(bytecode) == B.list(B.integer())
    end

    test "list/1 (syntax)" do
      bytecode = test_module([integer])
      assert convert_spec(bytecode) == B.list(B.integer())
    end

    test "keyword/0" do
      bytecode = test_module(keyword)
      assert convert_spec(bytecode) == B.keyword()
    end

    test "keyword/1" do
      bytecode = test_module(keyword(integer))
      assert convert_spec(bytecode) == B.keyword(B.integer())
    end

    test "mfa" do
      bytecode = test_module(mfa)
      assert convert_spec(bytecode) == B.mfa()
    end

    test "tuple" do
      bytecode = test_module({integer, atom})
      assert convert_spec(bytecode) == B.fixed_tuple([B.integer(), B.atom()])
    end

    test "tuple/0" do
      bytecode = test_module(tuple)
      assert convert_spec(bytecode) == B.tuple()
    end

    test "empty tuple" do
      bytecode = test_module({})
      assert convert_spec(bytecode) == B.fixed_tuple([])
    end

    test "literal integer" do
      bytecode = test_module(13)
      assert convert_spec(bytecode) == B.literal(13)
    end

    test "literal atom" do
      bytecode = test_module(:hi)
      assert convert_spec(bytecode) == B.literal(:hi)
    end

    test "literal true" do
      bytecode = test_module(true)
      assert convert_spec(bytecode) == B.literal(true)
    end

    test "literal nil" do
      bytecode = test_module(nil)
      assert convert_spec(bytecode) == B.literal(nil)
    end

    test "range/2" do
      bytecode = test_module(2..13)
      assert convert_spec(bytecode) == B.range(2, 13)
    end

    test "one_of" do
      bytecode = test_module(atom | integer | float)
      assert convert_spec(bytecode) == B.one_of([B.atom(), B.integer(), B.float()])
    end

    test "map/0" do
      bytecode = test_module(map)
      assert convert_spec(bytecode) == B.map()
    end

    test "none" do
      bytecode = test_module(none)
      assert convert_spec(bytecode) == B.none()
    end

    test "pid" do
      bytecode = test_module(pid)
      assert convert_spec(bytecode) == B.pid()
    end

    test "nonempty_list/0" do
      bytecode = test_module(nonempty_list)
      assert convert_spec(bytecode) == B.nonempty_list()
    end

    test "nonempty_list/0 (syntax)" do
      bytecode = test_module([...])
      assert convert_spec(bytecode) == B.nonempty_list()
    end

    test "nonempty_list/1" do
      bytecode = test_module(nonempty_list(integer))
      assert convert_spec(bytecode) == B.nonempty_list(B.integer())
    end

    test "nonempty_list/1 (syntax)" do
      bytecode = test_module([integer, ...])
      assert convert_spec(bytecode) == B.nonempty_list(B.integer())
    end
  end
end
