defmodule TypeCheck.Builtin.NamedType do
  defstruct [:name, :type]

  use TypeCheck
  @type! t :: %TypeCheck.Builtin.NamedType{name: atom(), type: TypeCheck.Type.t()}

  @type! problem_tuple ::
         {t(), :named_type, %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple())},
          any()}

  def stringify_name(atom, _) when is_atom(atom), do: to_string(atom)
  def stringify_name(str, _) when is_binary(str), do: to_string(str)
  def stringify_name(other, opts), do: TypeCheck.Protocols.Inspect.inspect(other, opts)

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      inner_check = TypeCheck.Protocols.ToCheck.to_check(s.type, param)

      quote generated: true, location: :keep do
        case unquote(inner_check) do
          {:ok, bindings} ->
            # Write it to a non-hygienic variable
            # that we can read from more outer-level types
            # unquote(Macro.var(s.name, TypeCheck.Builtin.NamedType)) = unquote(param)
            {:ok, [{unquote(s.name), unquote(param)} | bindings]}

          {:error, problem} ->
            {:error, {unquote(Macro.escape(s)), :named_type, %{problem: problem}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(literal, opts) do
      if Map.get(opts, :show_long_named_type, false) do
        @for.stringify_name(literal.name, opts)
        |> Inspect.Algebra.glue("::")
        |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(literal.type, Map.put(opts, :show_long_named_type, false)))
        |> Inspect.Algebra.group()
      else
        @for.stringify_name(literal.name, opts)
      end
    end
  end



  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        TypeCheck.Protocols.ToStreamData.to_gen(s.type)
      end
    end
  end
end
