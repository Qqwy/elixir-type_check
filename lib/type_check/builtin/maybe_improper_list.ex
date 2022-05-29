defmodule TypeCheck.Builtin.MaybeImproperList do
  defstruct [:element_type, :sentinel_type]

  use TypeCheck
  @type! t() :: t(TypeCheck.Type.t(), TypeCheck.Type.t())
  @type! t(element_type, sentinel_type) :: %__MODULE__{element_type: element_type, sentinel_type: sentinel_type}

  @type! problem_tuple ::
  {t(), :not_a_list, %{}, any()}
  | {t(), :element_error, %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()), index: non_neg_integer()}, any()}
  | {t(), :sentinel_error, %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple())}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: :true, location: :keep do
        case unquote(param) do
          x when not is_list(x) ->
            {:error, {unquote(Macro.escape(s)), :not_a_list, %{}, unquote(param)}}
          _ ->
        end
      end
    end
  end

  defp build_element_check(s, param) do
    element_check = TypeCheck.Protocols.ToCheck.to_check(s.element_type, Macro.var(:single_param, __MODULE__))
    sentinel_check = TypeCheck.Protocols.ToCheck.to_check(s.sentinel_type, Macro.var(:single_param, __MODULE__))

    quote generated: :true, location: :keep do
      orig_param = unquote(param)

      res =
        orig_param
        |> Enum.with_index
        |> TypeCHeck.Builtin.MaybeImproperList.reduce_while_improper({:ok, [], []}, fn {input, index}, {:ok, bindings, altered_param}, sentinel? ->
        var!(single_param, unquote(__MODULE__)) = input

        if sentinel? do
          case unquote(sentinel_check) do
              {:ok, sentinel_bindings, altered_sentinel} ->
                {:ok_sentinel, sentinel_bindings ++ bindings, altered_param, altered_sentinel}

              {:error, problem} ->
                  {:error,
                   {unquote(Macro.escape(s)), :sentinel_error, %{problem: problem, index: index},
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
          {:ok_sentinel, bindings, altered_param, altered_sentinel} ->
            altered_improper_list = [:lists.reverse(altered_param) | altered_sentinel]
            {:ok, bindings, altered_improper_list}
          {:ok, bindings, altered_param} ->
            altered_list = :lists.reverse(altered_param)
            {:ok, bindings, altered_list}
          other -> other
        end
    end
  end

  @doc false
  # Works similarly to `Enum.reduce_while`, but is able to handle improper lists.
  # The reduction fun is given a boolean as third parameter,
  # which is true when the first parameter is the sentinel (the non-`[]` at the end of an improper list)
  @typep elem() :: term()
  @typep acc() :: term()
  @typep reduction_fun :: (elem(), acc(), is_sentinel :: boolean() -> acc())
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
      sentinel ->
        fun.(sentinel, acc, true)
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(list, opts) do
      Inspect.Algebra.container_doc(
        Inspect.Algebra.color("maybe_improper_list(", :builtin_type, opts),
        [TypeCheck.Protocols.Inspect.inspect(list.element_type, opts)],
        [TypeCheck.Protocols.Inspect.inspect(list.sentinel_type, opts)],
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
        list =
          s.element_type
          |> TypeCheck.Protocols.ToStreamData.to_gen()
          |> StreamData.list_of()

        sentinel = TypeCheck.Protocols.ToStreamData.to_gen(s.sentinel_type)
        |> StreamData.map({list, sentinel}, fn {list_val, sentinel_val} ->
          [list_val | sentinel_val]
        end)
      end
    end
  end
end
