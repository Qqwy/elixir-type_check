defprotocol TypeCheck.Protocols.Inspect do
  @moduledoc false
  # This protocol can be overridden to have a different look
  # when inspected in a type context.

  @fallback_to_any true
  def inspect(struct, opts)
end

structs = [
  TypeCheck.Builtin.Any,
  TypeCheck.Builtin.None,
  TypeCheck.Builtin.Atom,
  TypeCheck.Builtin.Binary,
  TypeCheck.Builtin.Bitstring,
  TypeCheck.Builtin.Boolean,
  TypeCheck.Builtin.CompoundFixedMap,
  TypeCheck.Builtin.Guarded,
  TypeCheck.Builtin.FixedMap,
  TypeCheck.Builtin.FixedList,
  TypeCheck.Builtin.FixedTuple,
  TypeCheck.Builtin.Float,
  TypeCheck.Builtin.Function,
  TypeCheck.Builtin.Integer,
  TypeCheck.Builtin.PosInteger,
  TypeCheck.Builtin.NegInteger,
  TypeCheck.Builtin.NonNegInteger,
  TypeCheck.Builtin.List,
  TypeCheck.Builtin.MaybeImproperList,
  TypeCheck.Builtin.Literal,
  TypeCheck.Builtin.Lazy,
  TypeCheck.Builtin.Map,
  TypeCheck.Builtin.NamedType,
  TypeCheck.Builtin.Number,
  TypeCheck.Builtin.OneOf,
  TypeCheck.Builtin.PID,
  TypeCheck.Builtin.Port,
  TypeCheck.Builtin.Reference,
  TypeCheck.Builtin.Range,
  TypeCheck.Builtin.SizedBitstring,
  TypeCheck.Builtin.Tuple,
  TypeCheck.Builtin.ImplementsProtocol
]

for struct <- structs do
  defimpl Inspect, for: struct do
    def inspect(val, opts) do
      opts = Map.put(opts, :show_long_named_type, true)

      "#TypeCheck.Type<"
      |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(val, opts))
      |> Inspect.Algebra.glue(">")
      |> Inspect.Algebra.group()
    end
  end
end

defimpl TypeCheck.Protocols.Inspect, for: Any do
  def inspect(val, opts) do
    case val do
      somestruct = %_struct{} ->
        # always use 'Any' implementation rather than custom struct implementation,
        # because custom struct implementation cannot, in general,
        # handle types as their field values.
        Elixir.Inspect.Any.inspect(somestruct, opts)

      nonmap ->
        Elixir.Inspect.inspect(nonmap, opts)
    end

    # Elixir.Inspect.inspect(val, [opts])
    # Elixir.Inspect.Any.inspect(val, opts)
  end
end

# Override because Stream's normal Elixir implementation messes with TypeCheck's type-inspecting.
# This is probably a bit of a hack, but should be 'good enough' since using %Stream{}-structs themselves
# in types should be rare.
# c.f. https://github.com/Qqwy/elixir-type_check/issues/45
defimpl TypeCheck.Protocols.Inspect, for: Stream do
  def inspect(%{}, _opts) do
    import Elixir.Inspect.Algebra

    concat(["#Stream<", "[...]", ">"])
  end
end

defmodule TypeCheck.Inspect do
  @moduledoc false
  import Kernel, except: [inspect: 2]

  def inspect(type, opts \\ %Inspect.Opts{})

  def inspect(type, opts) when is_list(opts) do
    opts =
      if IO.ANSI.enabled?() do
        opts ++ [syntax_colors: default_colors()]
      else
        opts
      end
      |> Enum.reduce(struct(Inspect.Opts), fn {k, v}, res -> Map.put(res, k, v) end)

    inspect(type, opts)
  end

  def inspect(type, opts = %Inspect.Opts{}) do
    type
    |> TypeCheck.Protocols.Inspect.inspect(opts)
    |> Inspect.Algebra.format(opts.width)
  end

  def inspect_binary(type, opts \\ %Inspect.Opts{})

  def inspect_binary(type, opts) when is_list(opts) do
    opts =
      if IO.ANSI.enabled?() do
        opts ++ [syntax_colors: default_colors() ++ [reset: opts[:reset_color] || :default_color]]
      else
        opts
      end
      |> Enum.reduce(struct(Inspect.Opts), fn {k, v}, res -> Map.put(res, k, v) end)

    inspect_binary(type, opts)
  end

  def inspect_binary(type, opts = %Inspect.Opts{}) do
    TypeCheck.Inspect.inspect(type, opts)
    |> IO.iodata_to_binary()
  end

  @doc false
  def default_colors() do
    [
      atom: :cyan,
      string: :yellow,
      list: :default_color,
      boolean: :magenta,
      nil: :light_magenta,
      tuple: :default_color,
      binary: :green,
      map: :default_color,
      number: :yellow,
      range: :yellow,
      default: :default_color,
      named_type: :default_color,
      builtin_type: :default_color
    ]
  end
end
