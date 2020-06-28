defmodule TypeCheck.Builtin.Guarded do
  defstruct [:type, :guard]


  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      type_check = TypeCheck.Protocols.ToCheck.to_check(s.type, param)
      names_map =
        extract_names(s.type)
        |> Enum.map(fn name -> {name, {:unquote, [], [Macro.var(name, nil)]}} end)
        |> Enum.into(%{})
        |> Macro.escape(unquote: true)
      IO.inspect(names_map)
      res = quote do
        case unquote(type_check) do
          {:ok, bindings} ->
            # Shadows all but the most recently-bound value for each name
            bindings_map = Enum.into(bindings, %{})

            # Brings bindings in scope:
            unquote(names_map) = bindings_map

            if unquote(s.guard) do
              {:ok, bindings}
            else
              {:error, {unquote(Macro.escape(s)), :guard_failed, %{bindings: bindings_map}, unquote(param)}}
            end
          {:error, problem} ->
            {:error, {unquote(Macro.escape(s)), :type_failed, %{problem: problem}, unquote(param)}}
        end
      end

      IO.puts(Macro.to_string(res))
      res
    end

    defp extract_names(type) do
      case type do
        %TypeCheck.Builtin.NamedType{} ->
          [type.name | extract_names(type.type)]
        %TypeCheck.Builtin.FixedList{} ->
          Enum.flat_map(type.element_types, &extract_names/1)
        %TypeCheck.Builtin.Tuple{} ->
          Enum.flat_map(type.element_types, &extract_names/1)
        %TypeCheck.Builtin.FixedMap{} ->
          Enum.flat_map(type.keypairs, fn {key, value} -> extract_names(value) end)
        %TypeCheck.Builtin.List{} ->
          extract_names(type.element_type)
        %TypeCheck.Builtin.Map{} ->
          extract_names(type.key_type) ++ extract_names(type.value_type)
        %TypeCheck.Builtin.Either{} ->
          # NOTE this means that sometimes certain names are not set?!
          extract_names(type.left) ++ extract_names(type.right)
        other -> []
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      "("
      |> Inspect.Algebra.concat(TypeCheck.Protocols.Inspect.inspect(s.type, opts))
      |> Inspect.Algebra.glue("when")
      |> Inspect.Algebra.glue(Macro.to_string(s.guard))
      |> Inspect.Algebra.concat(")")
      |> Inspect.Algebra.group()
    end
  end
end
