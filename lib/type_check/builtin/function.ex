defmodule TypeCheck.Builtin.Function do
  defstruct [param_types: nil, return_type: %TypeCheck.Builtin.Any{}]

  use TypeCheck
  @opaque! t :: %TypeCheck.Builtin.Function{
    param_types: list(TypeCheck.Type.t()) | nil,
    return_type: TypeCheck.Type.t()
  }
  @type! problem_tuple :: {t(), :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        p = unquote(param)
        case p do
          unquote(is_function_check(s)) ->
            wrapped_fun = unquote(@for.contravariant_wrapper(s, param))
            {:ok, [], wrapped_fun}
          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end

    defp is_function_check(s) do
      case s.param_types do
        nil ->
          quote generated: true, location: :keep do
            x when is_function(x)
          end
        list ->
          quote generated: true, location: :keep do
            x when is_function(x, unquote(length(list)))
          end
      end
    end
  end

  def contravariant_wrapper(s, original) do
    case s do
      %{param_types: nil, return_type: %TypeCheck.Builtin.Any{}} ->
        original
      %{param_types: [], return_type: %TypeCheck.Builtin.Any{}} ->
        original
      %{param_types: nil, return_type: _type} ->
        # TODO. How to construct an arbitrary-arity function?
        original
      %{param_types: param_types, return_type: return_type} ->
        clean_params = Macro.generate_arguments(length(param_types), __MODULE__)
        param_checks =
          param_types
          |> Enum.zip(clean_params)
          |> Enum.with_index()
          |> Enum.flat_map(fn {{param_type, clean_param}, index} ->
            param_check_code(param_type, clean_param, index)
          end)

        return_code_check = TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:result, nil))

        quote do
          fn unquote_splicing(clean_params) ->
            with unquote_splicing(param_checks) do
              var!(result, nil) = unquote(original).(unquote_splicing(clean_params))
              # TypeCheck.conforms!(result, unquote(type))
              case unquote(return_code_check) do
                {:ok, _bindings, altered_return_value} ->
                  altered_return_value
                {:error, problem} ->
                  raise TypeCheck.TypeError,
                    {unquote(Macro.escape(s)), :return_error,
                     %{problem: problem, arguments: unquote(clean_params)}, var!(result, nil)}
              end
            else
              {{:error, problem}, index, param_type} ->
                raise TypeCheck.TypeError,
                {
                  {unquote(Macro.escape(s)), :param_error,
                   %{index: index, problem: problem}, unquote(clean_params)}, []}
            end
          end
        end
    end
  end

  def param_check_code(param_type, clean_param, index) do
    impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)
    quote generated: true, location: :keep do
      [
        {{:ok, _bindings, altered_param}, _index, _param_type} <- {unquote(impl), unquote(index), unquote(Macro.escape(param_type))},
        clean_param = altered_param
      ]
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      case s do
        %{param_types: nil, return_type: %TypeCheck.Builtin.Any{}} ->
          "function()"
          |> Inspect.Algebra.color(:builtin_type, opts)
        %{param_types: types, return_type: return_type} ->
          inspected_param_types =
            types
            |> Enum.map(&TypeCheck.Protocols.Inspect.inspect(&1, opts))
            |> Inspect.Algebra.fold_doc(fn doc, acc ->
              Inspect.Algebra.concat([doc, Inspect.Algebra.color(", ", :builtin_type, opts), acc])
            end)

          inspected_return_type = TypeCheck.Protocols.Inspect.inspect(return_type, opts)

          "("
          |> Inspect.Algebra.color(:builtin_type, opts)
          |> Inspect.Algebra.concat(inspected_param_types)
          |> Inspect.Algebra.glue(Inspect.Algebra.color("->", :builtin_type, opts))
          |> Inspect.Algebra.glue(inspected_return_type)
          |> Inspect.Algebra.concat(Inspect.Algebra.color(")", :builtin_type, opts))
      end
    end
  end

  # if Code.ensure_loaded?(StreamData) do
  #   defimpl TypeCheck.Protocols.ToStreamData do
  #     def to_gen(_s) do
  #       raise "Not implemented yet. PRs are welcome!"
  #     end
  #   end
  # end
end
