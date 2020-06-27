defmodule TypeCheck.Builtin.List do
  defstruct [:element_type]


  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(%{element_type: element_type}, param) do
      quote do
        case unquote(param) do
          x when not is_list(x) ->
            {:error, {TypeCheck.Builtin.List, :not_a_list, %{}, unquote(param)}}
          _ ->
            unquote(build_element_check(element_type, param))
        end
      end
    end

    defp build_element_check(%TypeCheck.Builtin.Any{}, _param) do
      :ok
    end
    defp build_element_check(element_type, param) do
      element_check = TypeCheck.Protocols.ToCheck.to_check(element_type, Macro.var(:single_param, nil))
      quote do
        unquote(param)
        |> Enum.with_index
        |> Enum.find_value(:ok, fn {input, index} ->
          var!(single_param) = input

          case unquote(element_check) do
            :ok ->
              false
            {:error, problem} -> {:error, {TypeCheck.Builtin.List, :element_error, %{problem: problem, index: index, element_type: unquote(Macro.escape(element_type))}, unquote(param)}}
          end
        end)
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(list, opts) do
      Inspect.Algebra.container_doc("list(", [TypeCheck.Protocols.Inspect.inspect(list.element_type, opts)], ")", opts, fn x, _ -> x end, [separator: "", break: :maybe])
    end
  end
end
