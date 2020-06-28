defmodule TypeCheck.Builtin.Map do
  defstruct [:key_type, :value_type]


  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when not is_map(x) ->
            {:error, {unquote(Macro.escape(s)), :not_a_map, %{}, unquote(param)}}
          _ ->
            unquote(build_keypairs_check(s.key_type, s.value_type, param, s))
        end
      end
    end

    defp build_keypairs_check(%TypeCheck.Builtin.Any{}, %TypeCheck.Builtin.Any{}, _param, _s) do
      :ok
    end

    defp build_keypairs_check(key_type, value_type, param, s) do
      key_check = TypeCheck.Protocols.ToCheck.to_check(key_type, Macro.var(:single_field_key, __MODULE__))
      value_check = TypeCheck.Protocols.ToCheck.to_check(value_type, Macro.var(:single_field_value, __MODULE__))
      quote do
        orig_param = unquote(param)

        orig_param
        |> Enum.reduce_while({:ok, []}, fn {key, value}, {:ok, bindings} ->
          var!(single_field_key, unquote(__MODULE__)) = key
          var!(single_field_value, unquote(__MODULE__)) = value

          case {unquote(key_check), unquote(value_check)} do
            {{:ok, key_bindings}, {:ok, value_bindings}} ->
              res = {:ok, value_bindings ++ key_bindings ++ bindings}
              {:cont, res}
            {{:error, problem}, _} ->
              res = {:error, {unquote(Macro.escape(s)), :key_error, %{problem: problem}, orig_param}}
              {:halt, res}
            {_, {:error, problem}} ->
              res = {:error, {unquote(Macro.escape(s)), :value_error, %{problem: problem}, orig_param}}
              {:halt, res}
          end
        end)
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(list, opts) do
      Inspect.Algebra.container_doc("map(", [TypeCheck.Protocols.Inspect.inspect(list.element_type, opts)], ")", opts, fn x, _ -> x end, [separator: "", break: :maybe])
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
         key_gen = to_gen(s.key_type)
         value_gen = to_gen(s.value_type)
         StreamData.map_of(key_gen, value_gen)
      end
    end
  end
end
