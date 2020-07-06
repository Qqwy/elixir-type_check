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
  TypeCheck.Builtin.Float,
  TypeCheck.Builtin.Integer,
  TypeCheck.Builtin.PosInteger,
  TypeCheck.Builtin.NegInteger,
  TypeCheck.Builtin.NonNegInteger,
  TypeCheck.Builtin.List,
  TypeCheck.Builtin.Literal,
  TypeCheck.Builtin.Map,
  TypeCheck.Builtin.NamedType,
  TypeCheck.Builtin.Number,
  TypeCheck.Builtin.OneOf,
  TypeCheck.Builtin.Range,
  TypeCheck.Builtin.Tuple,
]

for struct <- structs do
    defimpl Inspect, for: struct do
      def inspect(val, opts) do
        "#TypeCheck.Type<"
        |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(val, opts))
        |> Inspect.Algebra.glue(">")
        |> Inspect.Algebra.group
      end
    end
end

defimpl TypeCheck.Protocols.Inspect, for: Any do
  def inspect(val, opts) do
    Elixir.Inspect.inspect(val, opts)
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
    |> IO.iodata_to_binary
  end
end
