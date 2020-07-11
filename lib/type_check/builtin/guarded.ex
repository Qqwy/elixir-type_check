defmodule TypeCheck.Builtin.Guarded do
  defstruct [:type, :guard]

  @doc false
  def extract_names(type) do
    case type do
      %TypeCheck.Builtin.NamedType{} ->
        [type.name | extract_names(type.type)]

      %TypeCheck.Builtin.FixedList{} ->
        Enum.flat_map(type.element_types, &extract_names/1)

      %TypeCheck.Builtin.FixedTuple{} ->
        Enum.flat_map(type.element_types, &extract_names/1)

      %TypeCheck.Builtin.FixedMap{} ->
        Enum.flat_map(type.keypairs, fn {_key, value} -> extract_names(value) end)

      %TypeCheck.Builtin.List{} ->
        extract_names(type.element_type)

      %TypeCheck.Builtin.Map{} ->
        extract_names(type.key_type) ++ extract_names(type.value_type)

      %TypeCheck.Builtin.OneOf{} ->
        names =
          type.choices
          |> Enum.map(&extract_names/1)
          |> Enum.sort()
          |> Enum.into(%MapSet{})

        if MapSet.size(names) > 1 do
          raise """
          Attempted to construct a union type
          containing named types where one or multiple names
          do not exist in all of the possibilities:
          #{inspect(type)}
          """
        end

        Enum.at(names, 0)

      %TypeCheck.Builtin.Guarded{} ->
        # Recurse :-)
        extract_names(type.type)

      _other ->
        []
    end
  end

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      type_check = TypeCheck.Protocols.ToCheck.to_check(s.type, param)

      names_map =
        TypeCheck.Builtin.Guarded.extract_names(s.type)
        |> Enum.map(fn name -> {name, {:unquote, [], [Macro.var(name, nil)]}} end)
        |> Enum.into(%{})
        |> Macro.escape(unquote: true)

      quote location: :keep do
        case unquote(type_check) do
          {:ok, bindings} ->
            # Shadows all but the most recently-bound value for each name
            bindings_map = Enum.into(bindings, %{})

            unquote(names_map) = bindings_map

            if unquote(s.guard) do
              {:ok, bindings}
            else
              {:error,
               {unquote(Macro.escape(s)), :guard_failed, %{bindings: bindings_map},
                unquote(param)}}
            end

          {:error, problem} ->
            {:error,
             {unquote(Macro.escape(s)), :type_failed, %{problem: problem}, unquote(param)}}
        end
      end
    end

    def simple?(_) do
      false
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

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        # check_code = TypeCheck.Protocols.ToCheck.to_check(s, Macro.var(:value, nil))
        TypeCheck.Protocols.ToStreamData.to_gen(s.type)
        |> StreamData.filter(fn value ->
          TypeCheck.dynamic_conforms?(value, s)
        end)
      end
    end
  end
end
