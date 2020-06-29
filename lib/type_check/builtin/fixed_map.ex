defmodule TypeCheck.Builtin.FixedMap do
  defstruct [:keypairs]

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote location: :keep do
        with {:ok, []} <- unquote(map_check(param, s)),
             {:ok, []} <- unquote(build_keys_presence_ast(s.keypairs, param, s)),
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

    defp build_keys_presence_ast(keypairs, param, s) do
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
            {{:ok, value_bindings}, _key, _element_type} <- {unquote(value_check), unquote(key), unquote(Macro.escape(value_type))},
           bindings = value_bindings ++ bindings,
          ]
        end
      end)

        quote location: :keep do
          bindings = []
          with unquote_splicing(keypair_checks) do
            {:ok, bindings}
          else
            {{:error, error}, key, value_type} ->
              {:error, {unquote(Macro.escape(s)), :value_error, %{problem: error, key: key, value_type: value_type}, unquote(param)}}
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
