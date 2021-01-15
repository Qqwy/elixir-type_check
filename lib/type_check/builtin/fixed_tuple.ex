defmodule TypeCheck.Builtin.FixedTuple do
  defstruct [:element_types]

  use TypeCheck
  @type! t :: %__MODULE__{element_types: list(TypeCheck.Type.t())}

  @type! problem_tuple ::
         {t(), :not_a_tuple, %{}, any()}
         | {t(), :different_size, %{expected_size: integer()}, tuple()}
         | {t(), :element_error,
            %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()), index: integer()},
            tuple()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s = %{element_types: types_list}, param) do
      element_checks_ast = build_element_checks_ast(types_list, param, s)
      expected_size = length(types_list)

      quote generated: true, location: :keep do
        case unquote(param) do
          x when not is_tuple(x) ->
            {:error, {unquote(Macro.escape(s)), :not_a_tuple, %{}, x}}

          x when tuple_size(x) != unquote(expected_size) ->
            {:error,
             {unquote(Macro.escape(s)), :different_size, %{expected_size: unquote(expected_size)},
              x}}

          _ ->
            unquote(element_checks_ast)
        end
      end
    end

    defp build_element_checks_ast(types_list, param, s) do
      element_checks =
        types_list
        |> Enum.with_index()
        |> Enum.flat_map(fn {element_type, index} ->
          impl =
            TypeCheck.Protocols.ToCheck.to_check(
              element_type,
              quote generated: true, location: :keep do
                elem(unquote(param), unquote(index))
              end
            )

          quote generated: true, location: :keep do
            [
              {{:ok, element_bindings}, _index} <- {unquote(impl), unquote(index)},
              bindings = element_bindings ++ bindings
            ]
          end
        end)

      quote generated: true, location: :keep do
        bindings = []

        with unquote_splicing(element_checks) do
          {:ok, bindings}
        else
          {{:error, error}, index} ->
            {:error,
             {unquote(Macro.escape(s)), :element_error, %{problem: error, index: index},
              unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      element_types =
        case s.element_types do
          %TypeCheck.Builtin.FixedList{element_types: element_types} ->
            element_types

          %TypeCheck.Builtin.List{element_type: element_type} ->
            [element_type]

          other ->
            other
        end

      element_types
      |> List.to_tuple()
      |> Elixir.Inspect.inspect(%Inspect.Opts{
        opts
        | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2
      })
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        s.element_types
        |> Enum.map(&TypeCheck.Protocols.ToStreamData.to_gen/1)
        |> List.to_tuple()
        |> StreamData.tuple()
      end
    end
  end
end
