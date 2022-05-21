defmodule TypeCheck.Builtin.List do
  defstruct [:element_type]

  use TypeCheck
  @type! t :: t(TypeCheck.Type.t())
  @type! t(element_type) :: %__MODULE__{element_type: element_type}

  @type! problem_tuple ::
         {t(), :not_a_list, %{}, any()}
         | {t(), :element_error,
            %{
              problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()),
              index: non_neg_integer()
            }, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %{element_type: element_type}, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when not is_list(x) ->
            {:error, {unquote(Macro.escape(s)), :not_a_list, %{}, unquote(param)}}

          _ ->
            unquote(build_element_check(element_type, param, s))
        end
      end
    end

    defp build_element_check(%TypeCheck.Builtin.Any{}, param, _s) do
      quote generated: true, location: :keep do
        {:ok, [], unquote(param)}
      end
    end

    defp build_element_check(element_type, param, s) do
      element_check =
        TypeCheck.Protocols.ToCheck.to_check(element_type, Macro.var(:single_param, __MODULE__))

      quote generated: true, location: :keep do
        orig_param = unquote(param)

        res =
          orig_param
          |> Enum.with_index()
          |> Enum.reduce_while({:ok, [], []}, fn {input, index}, {:ok, bindings, altered_param} ->
            var!(single_param, unquote(__MODULE__)) = input

            case unquote(element_check) do
              {:ok, element_bindings, altered_element} ->
                {:cont, {:ok, element_bindings ++ bindings, [altered_element | altered_param]}}

              {:error, problem} ->
                problem =
                  {:error,
                  {unquote(Macro.escape(s)), :element_error, %{problem: problem, index: index},
                    orig_param}}

                {:halt, problem}
            end
          end)

          case res do
            {:ok, bindings, altered_param} -> {:ok, bindings, :lists.reverse(altered_param)}
            other -> other
          end
      end
    end

    def needs_slow_check?(s) do
      TypeCheck.Protocols.ToCheck.needs_slow_check?(s.element_type)
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(list, opts) do
      Inspect.Algebra.container_doc(
        Inspect.Algebra.color("list(", :builtin_type, opts),
        [TypeCheck.Protocols.Inspect.inspect(list.element_type, opts)],
        Inspect.Algebra.color(")", :builtin_type, opts),
        opts,
        fn x, _ -> x end,
        separator: "",
        break: :maybe
      )
      |> Inspect.Algebra.color(:builtin_type, opts)
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
