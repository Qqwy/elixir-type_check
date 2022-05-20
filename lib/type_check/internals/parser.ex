defmodule TypeCheck.Internals.Parser do
  @moduledoc false

  alias TypeCheck.Builtin, as: B

  @spec fetch_spec(atom() | list(), atom(), non_neg_integer()) ::
          {:error, String.t()} | {:ok, tuple()}
  def fetch_spec(module, function, arity) when is_atom(module) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} -> fetch_spec(specs, function, arity)
      :error -> {:error, "cannot fetch specs from the module"}
    end
  end

  def fetch_spec(specs, function, arity) when is_list(specs) do
    case specs |> Enum.find(fn {func, _spec} -> func == {function, arity} end) do
      {_func, [spec]} -> {:ok, spec}
      {_func, [_ | _]} -> {:error, "multiple specs for function"}
      {_func, _spec} -> {:error, "unsupported spec"}
      nil -> {:error, "cannot find spec for function"}
    end
  end

  # TODO(@orsinium):
  #  as_boolean
  #  map(a, b),
  #  mfa
  #  keyword(t)
  #  identifier
  #  sized bitstring
  #  structs
  @spec convert(tuple()) :: TypeCheck.Type.t()

  # basic types
  def convert({:type, _, :any, []}), do: B.any()
  def convert({:type, _, :atom, []}), do: B.atom()
  def convert({:type, _, :binary, []}), do: B.binary()
  def convert({:type, _, :bitstring, []}), do: B.bitstring()
  def convert({:type, _, :boolean, []}), do: B.boolean()
  def convert({:type, _, :pid, []}), do: B.pid()
  def convert({:type, _, :no_return, []}), do: B.none()
  def convert({:type, _, :none, []}), do: B.none()

  # unsupported by type_check yet
  def convert({:type, _, :reference, []}), do: B.any()
  def convert({:type, _, :port, []}), do: B.any()

  # numbers
  def convert({:type, _, :float, []}), do: B.float()
  def convert({:type, _, :integer, []}), do: B.integer()
  def convert({:type, _, :neg_integer, []}), do: B.neg_integer()
  def convert({:type, _, :non_neg_integer, []}), do: B.non_neg_integer()
  def convert({:type, _, :number, []}), do: B.number()
  def convert({:type, _, :pos_integer, []}), do: B.pos_integer()

  # literals
  def convert({:atom, _, val}), do: B.literal(val)
  def convert({:integer, _, val}), do: B.literal(val)

  def convert({:type, _, :range, [{:integer, _, left}, {:integer, _, right}]}),
    do: B.range(left, right)

  # aliases
  def convert({:type, _, :term, []}), do: B.term()
  def convert({:type, _, :arity, []}), do: B.arity()
  def convert({:type, _, :module, []}), do: B.module()
  def convert({:type, _, :nonempty_binary, []}), do: B.nonempty_binary()
  def convert({:type, _, :nonempty_bitstring, []}), do: B.nonempty_bitstring()
  def convert({:type, _, :byte, []}), do: B.byte()
  def convert({:type, _, :char, []}), do: B.char()
  def convert({:type, _, :node, []}), do: B.atom()
  def convert({:type, _, :charlist, []}), do: B.charlist()

  # shothands for generics
  def convert({:type, _, :fun, []}), do: B.function()
  def convert({:type, _, :fun, [{:type, _, :any}, ret_type]}), do: B.function(convert(ret_type))
  def convert({:type, _, :list, []}), do: B.list()
  def convert({:type, _, :map, :any}), do: B.map()
  def convert({:type, _, :nonempty_list, []}), do: B.nonempty_list()
  # improper lists are cursed, restrict it to regular lists
  def convert({:type, _, :nonempty_maybe_improper_list, []}), do: B.nonempty_list()
  def convert({:type, _, :tuple, :any}), do: B.tuple()

  # generics
  def convert({:type, _, :fun, [{:type, _, :product, arg_types}, ret_type]}),
    do: B.function(Enum.map(arg_types, &convert/1), convert(ret_type))

  def convert({:type, _, :bounded_fun, [t, _]}),
    # TODO(@orsinium): can we support constraints?
    do: convert(t)

  def convert({:type, _, :list, [t]}), do: B.list(convert(t))
  def convert({:type, _, :maybe_improper_list, [t, _tail]}), do: B.list(convert(t))
  def convert({:type, _, :nonempty_list, [t]}), do: B.nonempty_list(convert(t))

  def convert({:type, _, :nonempty_maybe_improper_list, [t, _tail]}),
    do: B.nonempty_list(convert(t))

  def convert({:type, _, :tuple, types}), do: B.fixed_tuple(Enum.map(types, &convert/1))
  def convert({:type, _, :union, types}), do: B.one_of(Enum.map(types, &convert/1))
  def convert({:ann_type, _, [_var, t]}), do: convert(t)

  # elixir types

  def convert({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, []]}),
    do: B.keyword()

  def convert({:remote_type, _, [{:atom, _, :elixir}, {:atom, _, :keyword}, [t]]}),
    do: B.keyword(convert(t))

  def convert({:remote_type, _, [{:atom, _, :String}, {:atom, _, :t}, []]}),
    do: B.bitstring()

  def convert({:remote_type, _, [{:atom, _, :"List.Chars"}, {:atom, _, :t}, []]}),
    do: B.charlist()

  def convert(_), do: B.any()
end
