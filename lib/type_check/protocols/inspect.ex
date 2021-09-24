defprotocol TypeCheck.Protocols.Inspect do
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
  TypeCheck.Builtin.Guarded,
  TypeCheck.Builtin.FixedMap,
  TypeCheck.Builtin.FixedList,
  TypeCheck.Builtin.FixedTuple,
  TypeCheck.Builtin.Float,
  TypeCheck.Builtin.Integer,
  TypeCheck.Builtin.PosInteger,
  TypeCheck.Builtin.NegInteger,
  TypeCheck.Builtin.NonNegInteger,
  TypeCheck.Builtin.List,
  TypeCheck.Builtin.Literal,
  TypeCheck.Builtin.Lazy,
  TypeCheck.Builtin.Map,
  TypeCheck.Builtin.NamedType,
  TypeCheck.Builtin.Number,
  TypeCheck.Builtin.OneOf,
  TypeCheck.Builtin.PID,
  TypeCheck.Builtin.Range,
  TypeCheck.Builtin.Tuple,
  TypeCheck.Builtin.ImplementsProtocol,
]

for struct <- structs do
  defimpl Inspect, for: struct do
    def inspect(val, opts) do
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
  def inspect(type, opts \\ %Inspect.Opts{}) do
    type
    |> TypeCheck.Protocols.Inspect.inspect(opts)
    |> Inspect.Algebra.format(opts.width)
  end

  def inspect_binary(type, opts \\ %Inspect.Opts{}) do
    TypeCheck.Inspect.inspect(type, opts)
    |> IO.iodata_to_binary()
  end
end
