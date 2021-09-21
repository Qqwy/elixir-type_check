defmodule TypeCheck.Builtin.Guarded do
  defstruct [:type, :guard]

  use TypeCheck
  import TypeCheck.Type.StreamData
  @type! ast() :: term() |> wrap_with_gen(&TypeCheck.Builtin.Guarded.ast_gen/1)
  def ast_gen(term) do
    Macro.escape(term)
  end

  @type! t() :: %TypeCheck.Builtin.Guarded{type: TypeCheck.Type.t(), guard: ast()}

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

      type_names = MapSet.new(TypeCheck.Builtin.Guarded.extract_names(s.type))
      guard_names = TypeCheck.Internals.Helper.extract_vars_from_ast(s.guard)
      used_and_existing_names = MapSet.intersection(type_names, guard_names)

      names_map =
        used_and_existing_names
        |> Enum.map(fn name -> {name, {:unquote, [], [Macro.var(name, nil)]}} end)
        |> Enum.into(%{})
        |> Macro.escape(unquote: true)

      quote generated: true, location: :keep do
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
