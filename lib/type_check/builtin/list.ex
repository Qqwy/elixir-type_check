defmodule TypeCheck.Builtin.List do
  defstruct [:element_type]

  use TypeCheck
  opaque t :: %__MODULE__{element_type: TypeCheck.Type.t()}

  type problem_tuple ::
         {t(), :not_a_list, %{}, any()}
         | {t(), :element_error,
            %{
              problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()),
              index: non_neg_integer()
            }, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %{element_type: element_type}, param) do
      quote do
        case unquote(param) do
          x when not is_list(x) ->
            {:error, {unquote(Macro.escape(s)), :not_a_list, %{}, unquote(param)}}

          _ ->
            unquote(build_element_check(element_type, param, s))
        end
      end
    end

    def simple?(_) do
      false
    end

    defp build_element_check(%TypeCheck.Builtin.Any{}, _param, _s) do
      quote location: :keep do
        {:ok, []}
      end
    end

    defp build_element_check(element_type, param, s) do
      element_check =
        TypeCheck.Protocols.ToCheck.to_check(element_type, Macro.var(:single_param, __MODULE__))

      quote do
        orig_param = unquote(param)

        orig_param
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {input, index}, {:ok, bindings} ->
          var!(single_param, unquote(__MODULE__)) = input

          case unquote(element_check) do
            {:ok, element_bindings} ->
              {:cont, {:ok, element_bindings ++ bindings}}

            {:error, problem} ->
              problem =
                {:error,
                 {unquote(Macro.escape(s)), :element_error, %{problem: problem, index: index},
                  orig_param}}

              {:halt, problem}
          end
        end)
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(list, opts) do
      Inspect.Algebra.container_doc(
        "list(",
        [TypeCheck.Protocols.Inspect.inspect(list.element_type, opts)],
        ")",
        opts,
        fn x, _ -> x end,
        separator: "",
        break: :maybe
      )
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        s.element_type
        |> TypeCheck.Protocols.ToStreamData.to_gen()
        |> StreamData.list_of()
      end
    end
  end
end
