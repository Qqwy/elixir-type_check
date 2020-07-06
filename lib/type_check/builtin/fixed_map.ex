defmodule TypeCheck.Builtin.FixedMap do
  @moduledoc """
  Checks whether the value is a list with the expected elements

  On failure returns a problem tuple with:
  - `:not_a_map` if the value is not a map
  - `:missing_keys` if the value does not have all of the expected keys. The extra information contains in this case `:keys` with a list of keys that are missing.
  - `:value_error` if one of the elements does not match. The extra information contains in this case `:problem` and `:key` to indicate what and where the problem occured.
  """
  defstruct [:keypairs]

  use TypeCheck
  type t :: %__MODULE__{keypairs: list({any(), any()})}
  type problem_tuple :: (
    {t(), :not_a_map, %{}, any()}
    | {t(), :missing_keys, %{keys: list(atom())}, map()}
    | {t(), :value_error, %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()), key: any()}, map()}
  )


  defimpl TypeCheck.Protocols.ToCheck do
    # Optimization: If we have no expectations on keys -> value types, remove those useless checks.
    def to_check(s = %TypeCheck.Builtin.FixedMap{keypairs: keypairs}, param) when keypairs == [] do
        map_check(param, s)
    end

    def to_check(s, param) do
      quote location: :keep do
        with {:ok, []} <- unquote(map_check(param, s)),
             {:ok, []} <- unquote(build_keys_presence_ast(s, param)),
             {:ok, bindings3} <- unquote(build_keypairs_checks_ast(s.keypairs, param, s)) do
          {:ok, bindings3}
        end
      end
    end

    defp map_check(param, s) do
      quote location: :keep do
        if is_map(unquote(param)) do
          {:ok, []}
        else
          {:error, {unquote(Macro.escape(s)), :not_a_map, %{}, unquote(param)}}
        end
      end
    end

    # TODO raise on superfluous keys (just like Elixir's built-in typespecs do not allow them)
    defp build_keys_presence_ast(s, param) do
      required_keys =
        s.keypairs
        |> Enum.into(%{})
        |> Map.keys
      quote location: :keep do
        actual_keys = unquote(param) |> Map.keys
        case unquote(required_keys) -- actual_keys do
          [] -> {:ok, []}
          missing_keys ->
            {:error, {unquote(Macro.escape(s)), :missing_keys, %{keys: missing_keys}, unquote(param)}}
        end
      end
    end

    defp build_keypairs_checks_ast(keypairs, param, s) do
      keypair_checks =
        keypairs
        |> Enum.flat_map(fn {key, value_type} ->
        value_check = TypeCheck.Protocols.ToCheck.to_check(value_type, quote do Map.fetch!(unquote(param), unquote(key)) end)
        quote location: :keep do
          [
            {{:ok, value_bindings}, _key} <- {unquote(value_check), unquote(key)},
           bindings = value_bindings ++ bindings,
          ]
        end
      end)

        quote location: :keep do
          bindings = []
          with unquote_splicing(keypair_checks) do
            {:ok, bindings}
          else
            {{:error, error}, key} ->
              {:error, {unquote(Macro.escape(s)), :value_error, %{problem: error, key: key}, unquote(param)}}
          end
        end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      map = Enum.into(s.keypairs, %{})
      case Map.get(map, :__struct__) do
        %TypeCheck.Builtin.Literal{value: value} ->
          # Make sure we render structs as structs
          map = Map.put(map, :__struct__, value)
          Elixir.Inspect.inspect(map, %Inspect.Opts{opts | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2})
        _ ->
          Elixir.Inspect.inspect(map, %Inspect.Opts{opts | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2})
      end
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        s.keypairs
        |> Enum.map(fn {key, value} -> {key, TypeCheck.Protocols.ToStreamData.to_gen(value)} end)
        |> StreamData.fixed_map()
      end
    end
  end
end
