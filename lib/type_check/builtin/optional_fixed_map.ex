defmodule TypeCheck.Builtin.OptionalFixedMap do
  @moduledoc """
  Checks whether the value is a map with a optional set of keys

  On failure returns a problem tuple with:
  - `:not_a_map` if the value is not a map
  - `:superfluous_keys` if the value have any keys other than the expected keys. The extra information contains in this case `:keys` with a list of keys that are superfluous.
  - `:value_error` if one of the elements does not match. The extra information contains in this case `:problem` and `:key` to indicate what and where the problem occurred.
  """
  defstruct [:keypairs]

  use TypeCheck
  @type! t :: %__MODULE__{keypairs: list({term(), TypeCheck.Type.t()})}

  @type! problem_tuple ::
           {t(), :not_a_map, %{}, any()}
           | {t(), :superfluous_keys, %{keys: list(atom())}, map()}
           | {t(), :value_error,
              %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()), key: any()}, map()}

  defimpl TypeCheck.Protocols.Escape do
    def escape(s) do
      update_in(
        s.keypairs,
        &Enum.map(&1, fn {key, val} -> {key, TypeCheck.Protocols.Escape.escape(val)} end)
      )
    end
  end

  defimpl TypeCheck.Protocols.ToCheck do
    # Optimization: If we have no expectations on keys -> value types, remove those useless checks.
    def to_check(s = %TypeCheck.Builtin.FixedMap{keypairs: keypairs}, param)
        when keypairs == [] do
      map_check(param, s)
    end

    def to_check(s, param) do
      res =
        quote generated: true, location: :keep do
          with {:ok, _, _} <- unquote(map_check(param, s)),
               {:ok, _, _} <- unquote(build_superfluous_keys_ast(s, param)) do
            unquote(build_keypairs_checks_ast(s.keypairs, param, s))
          end
        end

      res
    end

    defp map_check(param, s) do
      quote generated: true, location: :keep do
        case unquote(param) do
          val when is_map(val) ->
            {:ok, [], val}

          other ->
            {:error, {unquote(TypeCheck.Internals.Escaper.escape(s)), :not_a_map, %{}, other}}
        end
      end
    end

    defp build_superfluous_keys_ast(s, param) do
      required_keys = for {key, _} <- s.keypairs, do: key

      quote generated: true, location: :keep do
        actual_keys = unquote(param) |> Map.keys()

        case actual_keys -- unquote(required_keys) do
          [] ->
            {:ok, [], unquote(param)}

          superfluous_keys ->
            {:error,
             {unquote(TypeCheck.Internals.Escaper.escape(s)), :superfluous_keys,
              %{keys: superfluous_keys}, unquote(param)}}
        end
      end
    end

    defp build_keypairs_checks_ast(keypairs, param, s) do
      keypair_checks =
        keypairs
        |> Enum.flat_map(fn {key, value_type} ->
          value_check =
            TypeCheck.Protocols.ToCheck.to_check(
              value_type,
              Macro.var(:value, __MODULE__)
            )

          quote generated: true, location: :keep do
            [
              result =
                case Map.fetch(unquote(param), unquote(key)) do
                  {:ok, var!(value, unquote(__MODULE__))} ->
                    with {:ok, value_bindings, altered_element} <- unquote(value_check) do
                      {:ok, value_bindings, {:present, altered_element}}
                    end

                  :error ->
                    {:ok, [], :not_present}
                end,
              {{:ok, value_bindings, altered_element_result}, _key} <- {result, unquote(key)},
              bindings = value_bindings ++ bindings,
              altered_keypairs =
                case altered_element_result do
                  {:present, altered_element} ->
                    [{unquote(key), altered_element} | altered_keypairs]

                  :not_present ->
                    altered_keypairs
                end
            ]
          end
        end)

      quote generated: true, location: :keep do
        bindings = []
        altered_keypairs = []

        with unquote_splicing(keypair_checks),
             altered_param = :maps.from_list(altered_keypairs) do
          {:ok, bindings, altered_param}
        else
          {{:error, error}, key} ->
            {:error,
             {unquote(TypeCheck.Internals.Escaper.escape(s)), :value_error,
              %{problem: error, key: key}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      # map = case s.keypairs do
      # list when is_list(list) ->
      map = Enum.into(s.keypairs, %{})

      # %TypeCheck.Builtin.List{element_type: %TypeCheck.Builtin.FixedTuple{element_types: [key_type, value_type]}} ->
      #         # Special case for when calling on the 'meta' FixedMap
      #         # i.e. `TypeCheck.Builtin.FixedMap.t()`
      #   %{key_type => value_type}

      # end
      # IO.inspect(s, structs: false, label: :inspect_my_fixed_map)
      # map = Enum.into(s.keypairs, %{})

      case Map.get(map, :__struct__) do
        %TypeCheck.Builtin.Literal{value: value} ->
          # Make sure we render structs as structs
          map = Map.put(map, :__struct__, value)

          # Ensure that structs can override their normal inspect
          # by implementing the TypeCheck Inspect protocol:
          TypeCheck.Protocols.Inspect.inspect(map, %Inspect.Opts{
            opts
            | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2
          })

        _ ->
          # Ensure that structs can override their normal inspect
          # by implementing the TypeCheck Inspect protocol:
          TypeCheck.Protocols.Inspect.inspect(map, %Inspect.Opts{
            opts
            | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2
          })
      end
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        s.keypairs
        |> Enum.map(fn {key, value} ->
          {key, TypeCheck.Protocols.ToStreamData.to_gen(value)}
        end)
        |> StreamData.fixed_map()
      end
    end
  end
end
