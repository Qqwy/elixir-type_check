defprotocol TypeCheck.Protocols.Inspect do
  def inspect(struct, opts)
end

structs = [
  TypeCheck.Builtin.Any,
  TypeCheck.Builtin.Atom,
  TypeCheck.Builtin.Either,
  TypeCheck.Builtin.Float,
  TypeCheck.Builtin.Integer,
  TypeCheck.Builtin.List,
  TypeCheck.Builtin.Literal,
  TypeCheck.Builtin.Range,
  TypeCheck.Builtin.Tuple,
]

for struct <- structs do
    defimpl Inspect, for: struct do
      def inspect(val, opts) do
        # ["#TypeCheck<", TypeCheck.Protocols.Inspect.inspect(val, opts), ">"]
        "#TypeCheck.Type<"
        |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(val, opts))
        |> Inspect.Algebra.glue(">")
        |> Inspect.Algebra.group
      end
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
