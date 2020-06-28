defmodule TypeCheck.Builtin.FixedList do
  defstruct [:element_types]

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      expected_length = length(s.element_types)
      element_checks_ast = build_element_checks_ast(s.element_types, param, s)

      quote do
        case unquote(param) do
          x when not is_list(x) ->
            {:error, {unquote(Macro.escape(s)), :not_a_list, %{}, x}}
          x when length(x) != unquote(expected_length) ->
            {:error, {unquote(Macro.escape(s)), :different_length, %{expected_length: unquote(expected_length)}, x}}
          _ ->
            unquote(element_checks_ast)
        end
      end
    end

    def build_element_checks_ast(element_types, param, s) do
      element_checks =
        element_types
        |> Enum.with_index
        |> Enum.map(fn {element_type, index} ->
          impl = TypeCheck.Protocols.ToCheck.to_check(element_type, quote do hd(var!(rest, unquote(__MODULE__))) end)
          quote location: :keep do
            {:ok, index, element_type, var!(rest, unquote(__MODULE__))} <- {unquote(impl), unquote(index), unquote(Macro.escape(element_type)), tl(var!(rest, unquote(__MODULE__)))}
          end
        end)

        quote location: :keep do
          with var!(rest, unquote(__MODULE__)) = unquote(param), unquote_splicing(element_checks) do
            :ok
          else
            {{:error, error}, index, element_type, _rest} ->
              {:error, {unquote(Macro.escape(s)), :element_error, %{problem: error, index: index, element_type: element_type}, unquote(param)}}
          end
        end
    end
  end
end
