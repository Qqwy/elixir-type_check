defmodule TypeCheck.Builtin.NamedType do
  defstruct [:name, :type, :local, :type_kind]

  use TypeCheck
  @type! t :: %TypeCheck.Builtin.NamedType{name: atom(), type: TypeCheck.Type.t(), local: boolean(), type_kind: :type | :typep | :opaque}

  @type! problem_tuple ::
         {t(), :named_type, %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple())},
          any()}

  def stringify_name(atom, _opts) when is_atom(atom), do: to_string(atom)
  def stringify_name(str, _opts) when is_binary(str), do: to_string(str)
  def stringify_name(other, opts), do: TypeCheck.Protocols.Inspect.inspect(other, opts)

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      inner_check = TypeCheck.Protocols.ToCheck.to_check(s.type, param)

      if s.type_kind == :opaque do
        # Do not expose binding on opaque types
        quote generated: true, location: :keep do
          inner_res = unquote(inner_check)
          case inner_res do
            {:ok, _bindings, altered_inner} ->
              # Reset bindings
              {:ok, [], altered_inner}
            {:error, problem} ->
              {:error, {unquote(Macro.escape(s)), :named_type, %{problem: problem}, unquote(param)}}
          end
        end
      else
        quote generated: true, location: :keep do
          inner_res = unquote(inner_check)
          case inner_res do
            {:ok, bindings, altered_inner} ->
              # Write it to a non-hygienic variable
              # that we can read from more outer-level types
              # unquote(Macro.var(s.name, TypeCheck.Builtin.NamedType)) = unquote(param)
              {:ok, [{unquote(s.name), unquote(param)} | bindings], altered_inner}

            {:error, problem} ->
              {:error, {unquote(Macro.escape(s)), :named_type, %{problem: problem}, unquote(param)}}
          end
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      if Map.get(opts, :show_long_named_type, false) || s.local do
        @for.stringify_name(s.name, opts)
        |> Inspect.Algebra.glue("::")
        |> Inspect.Algebra.glue(TypeCheck.Protocols.Inspect.inspect(s.type, Map.put(opts, :show_long_named_type, false)))
        |> Inspect.Algebra.group()
      else
        @for.stringify_name(s.name, opts)
      end
      |> Inspect.Algebra.color(:named_type, opts)
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
