defmodule TypeCheck.Builtin.FixedList do
  @moduledoc """
  Checks whether the value is a list with the expected elements

  On failure returns a problem tuple with:
    - `:not_a_list` if the value is not a list
    - `:different_length` if the value is a list but not of equal size.
    - `:element_error` if one of the elements does not match. The extra information contains in this case `:problem` and `:index` to indicate what and where the problem occured.
  """

  defstruct [:element_types]

  use TypeCheck
  @type! t :: %__MODULE__{element_types: list(TypeCheck.Type.t())}

  @type! problem_tuple ::
         {:not_a_list, %{}, any()}
         | {:different_length, %{expected_length: non_neg_integer()}, list()}
         | {:element_error,
            %{problem: lazy(TypeCheck.TypeError.Formatter.problem_tuple()), index: non_neg_integer()},
            list()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      expected_length = length(s.element_types)
      element_checks_ast = build_element_checks_ast(s.element_types, param, s)

      quote generated: :true, location: :keep do
        case unquote(param) do
          x when not is_list(x) ->
            {:error, {:not_a_list, %{}, x}}

          x when length(x) != unquote(expected_length) ->
            {:error,
             {:different_length,
              %{expected_length: unquote(expected_length)}, x}}

          _ ->
            unquote(element_checks_ast)
        end
      end
    end

    def build_element_checks_ast(element_types, param, _s) do
      element_checks =
        element_types
        |> Enum.with_index()
        |> Enum.flat_map(fn {element_type, index} ->
          impl =
            TypeCheck.Protocols.ToCheck.to_check(
              element_type,
              quote generated: true, location: :keep do
                hd(var!(rest, unquote(__MODULE__)))
              end
            )

          quote generated: true, location: :keep do
            [
              {{:ok, element_bindings, altered_element}, index, var!(rest, unquote(__MODULE__))} <- {unquote(impl), unquote(index), tl(var!(rest, unquote(__MODULE__)))},
              bindings = element_bindings ++ bindings,
              altered_param = [altered_element | altered_param]
            ]
          end
        end)

      quote generated: true, location: :keep do
        bindings = []
        altered_param = []

        with var!(rest, unquote(__MODULE__)) = unquote(param),
             unquote_splicing(element_checks),
             altered_param = :lists.reverse(altered_param)
          do
          {:ok, bindings, altered_param}
        else
          {{:error, error}, index, _rest} ->
            {:error,
             {:element_error, %{problem: error, index: index},
              unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Escape do
    def escape(s) do
      update_in(s.element_types, &Enum.map(&1, fn val -> TypeCheck.Protocols.Escape.escape(val) end))
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      s.element_types
      |> Elixir.Inspect.inspect(%Inspect.Opts{
        opts
        | inspect_fun: &TypeCheck.Protocols.Inspect.inspect/2
      })
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        s.element_types
        |> Enum.map(&TypeCheck.Protocols.ToStreamData.to_gen/1)
        |> StreamData.fixed_list()
      end
    end
  end
end
