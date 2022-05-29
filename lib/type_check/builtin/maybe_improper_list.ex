defmodule TypeCheck.Builtin.MaybeImproperList do
  defstruct [:element_type, :terminator_type]

  use TypeCheck
  @type! t() :: t(TypeCheck.Type.t(), TypeCheck.Type.t())
  @type! t(element_type, terminator_type) :: %__MODULE__{
           element_type: element_type,
           terminator_type: terminator_type
         }

  @type! problem_tuple ::
           {t(), :not_a_list, %{}, any()}
           | {t(), :element_error,
              %{
                problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()),
                index: non_neg_integer()
              }, any()}
           | {t(), :terminator_error,
              %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple())}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when not is_list(x) ->
            {:error, {unquote(Macro.escape(s)), :not_a_list, %{}, unquote(param)}}

          _ ->
            unquote(build_element_check(s, param))
        end
      end
    end

    defp build_element_check(s, param) do
      element_check =
        TypeCheck.Protocols.ToCheck.to_check(s.element_type, Macro.var(:single_param, __MODULE__))

      terminator_check =
        TypeCheck.Protocols.ToCheck.to_check(
          s.terminator_type,
          Macro.var(:single_param, __MODULE__)
        )

      quote generated: true, location: :keep do
        orig_param = unquote(param)

        res =
          orig_param
          |> TypeCheck.Builtin.MaybeImproperList.with_index_improper()
          |> TypeCheck.Builtin.MaybeImproperList.reduce_while_improper(
          {:ok, [], []}, fn {input,
                             index},
        {:ok,
         bindings,
         altered_param},
          terminator? ->
            var!(single_param, unquote(__MODULE__)) = input

            if terminator? do
              case unquote(terminator_check) do
                {:ok, terminator_bindings, altered_terminator} ->
                  {:ok_terminator, terminator_bindings ++ bindings, altered_param, altered_terminator}

                {:error, problem} ->
                  {:error,
                   {unquote(Macro.escape(s)), :terminator_error, %{problem: problem, index: index},
                    orig_param}}
              end
            else
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
            end
          end)

        case res do
          {:ok_terminator, bindings, altered_param, altered_terminator} ->
            altered_improper_list = :lists.reverse(altered_param) ++ altered_terminator
            {:ok, bindings, altered_improper_list}

          {:ok, bindings, altered_param} ->
            altered_list = :lists.reverse(altered_param)
            {:ok, bindings, altered_list}

          other ->
            other
        end
      end
    end
  end

  @doc false
  # Similar to Enum.with_index, but works on improper lists
  @typep elem() :: term()
  @typep terminator() :: term()
  @spec with_index_improper(maybe_improper_list(elem(), terminator())) :: maybe_improper_list({elem(), non_neg_integer()}, {terminator(), non_neg_integer()})
  def with_index_improper(maybe_improper_list) do
    do_with_index_improper(maybe_improper_list, [], 0)
  end

  defp do_with_index_improper(maybe_improper_list, result, count) do
    case maybe_improper_list do
      [] -> :lists.reverse(result)
      [head | tail] ->
        do_with_index_improper(tail, [{head, count} | result], count + 1)
      terminator ->
        rest_list = :lists.reverse(result)
        terminator_with_index = {terminator, count}
        rest_list ++ terminator_with_index
    end
  end

  @doc false
  # Works similarly to `Enum.reduce_while`, but is able to handle improper lists.
  # The reduction fun is given a boolean as third parameter,
  # which is true when the first parameter is the terminator (the non-`[]` at the end of an improper list)
  @typep acc() :: term()
  @typep reduction_fun :: (elem(), acc(), is_terminator :: boolean() -> acc())
  @spec reduce_while_improper(maybe_improper_list(), acc(), reduction_fun()) :: acc()
  def reduce_while_improper(maybe_improper_list, acc, fun) do
    case maybe_improper_list do
      [] ->
        acc

      [head | tail] ->
        case fun.(head, acc, false) do
          {:cont, new_acc} ->
            reduce_while_improper(tail, new_acc, fun)

          {:halt, final_acc} ->
            final_acc
        end

      terminator ->
        fun.(terminator, acc, true)
    end
  end

  def empty?(list) do
    case list do
      [] -> true
      _other -> false
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(list, opts) do
      Inspect.Algebra.container_doc(
        Inspect.Algebra.color("maybe_improper_list(", :builtin_type, opts),
        [
          TypeCheck.Protocols.Inspect.inspect(list.element_type, opts),
          TypeCheck.Protocols.Inspect.inspect(list.terminator_type, opts)
        ],
        Inspect.Algebra.color(")", :builtin_type, opts),
        opts,
        fn x, _ -> x end,
        separator: ",",
        break: :maybe
      )
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        element_gen =  TypeCheck.Protocols.ToStreamData.to_gen(s.element_type)
        terminator_gen = TypeCheck.Protocols.ToStreamData.to_gen(s.terminator_type)
        StreamData.maybe_improper_list_of(element_gen, terminator_gen)
      end
    end
  end
end
