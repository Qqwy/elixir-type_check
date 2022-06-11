defmodule TypeCheck.Builtin.NamedType do
  defstruct [:name, :type, :local, :type_kind, :called_as]

  use TypeCheck
  @type! t :: %TypeCheck.Builtin.NamedType{name: atom(), type: TypeCheck.Type.t(), local: boolean(), type_kind: :type | :typep | :opaque, called_as: nil | {atom(), list(any())}}

  @type! problem_tuple ::
         {t(), :named_type, %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple())},
          any()}

  def stringify_name(atom, _opts) when is_atom(atom), do: to_string(atom)
  def stringify_name(str, _opts) when is_binary(str), do: to_string(str)
  def stringify_name(other, opts), do: TypeCheck.Protocols.Inspect.inspect(other, opts)


  defimpl TypeCheck.Protocols.Escape do
    def escape(s) do
      case s do
        %{called_as: {module, function, args}, type_kind: kind} when kind in [:type, :opaque] ->
          escaped_args = args
          |> Enum.map(&TypeCheck.Protocols.Escape.escape/1)
          |> Macro.escape(unquote: true)

          res = quote do
            unquote(module).unquote(function)(unquote_splicing(escaped_args))
          end
          {:unquote, [], [res]}
        _other ->
          %{s| type: TypeCheck.Protocols.Escape.escape(s.type)}
          # other
      end
    end
  end

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      inner_check = TypeCheck.Protocols.ToCheck.to_check(s.type, param)

      if !s.local do
        # Do not expose bindings across non-local types
        quote generated: true, location: :keep do
          inner_res = unquote(inner_check)
          case inner_res do
            {:ok, _bindings, altered_inner} ->
              # Reset bindings
              {:ok, [], altered_inner}
            {:error, problem} ->
              {:error, {unquote(TypeCheck.Internals.Escaper.escape(s)), :named_type, %{problem: problem}, unquote(param)}}
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
              {:error, {unquote(TypeCheck.Internals.Escaper.escape(s)), :named_type, %{problem: problem}, unquote(param)}}
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
