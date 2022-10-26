defmodule TypeCheck.Builtin.Function do
  defstruct param_types: nil, return_type: %TypeCheck.Builtin.Any{}

  use TypeCheck

  @opaque! t :: %TypeCheck.Builtin.Function{
             param_types: list(TypeCheck.Type.t()) | nil,
             return_type: TypeCheck.Type.t()
           }
  @type! problem_tuple :: {:no_match, %{}, any()}

  defimpl TypeCheck.Protocols.Escape do
    def escape(s) do
      s
      |> Map.update!(:param_types, fn
        nil -> nil
        list when is_list(list) -> Enum.map(list, &TypeCheck.Protocols.Escape.escape(&1))
      end)
      |> Map.update!(:return_type, &TypeCheck.Protocols.Escape.escape(&1))
    end
  end

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        p = unquote(param)

        case p do
          unquote(is_function_check(s)) ->
            wrapped_fun = unquote(@for.contravariant_wrapper(s, param))
            {:ok, [], wrapped_fun}

          _ ->
            {:error, {:no_match, %{}, unquote(param)}}
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

      %{param_types: nil, return_type: return_type} ->
        quote generated: true,
              location: :keep,
              bind_quoted: [
                fun: original,
                s: Macro.escape(s),
                return_type: Macro.escape(return_type)
              ] do
          {:arity, arity} = Function.info(fun, :arity)
          clean_params = Macro.generate_arguments(arity, __MODULE__)

          return_code_check =
            TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:result, nil))

          wrapper_ast =
            quote do
              fn unquote_splicing(clean_params) ->
                var!(result, nil) = var!(fun).(unquote_splicing(clean_params))

                case unquote(return_code_check) do
                  {:ok, _bindings, altered_return_value} ->
                    altered_return_value

                  {:error, problem} ->
                    raise TypeCheck.TypeError,
                          {:return_error,
                           %{problem: problem, arguments: unquote(clean_params)},
                           var!(result, nil)}
                end
              end
            end

          {fun, _} = Code.eval_quoted(wrapper_ast, [fun: fun], __ENV__)

          fun
        end

      %{param_types: [], return_type: return_type} ->
        return_code_check =
          TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:result, nil))

        quote generated: true, location: :keep do
          fn ->
            var!(result, nil) = unquote(original).()

            case unquote(return_code_check) do
              {:ok, _bindings, altered_return_value} ->
                altered_return_value

              {:error, problem} ->
                raise TypeCheck.TypeError,
                      {unquote(Macro.escape(s)), :return_error,
                       %{problem: problem, arguments: []}, var!(result, nil)}
            end
          end
        end

      %{param_types: param_types, return_type: return_type} ->
        clean_params = Macro.generate_arguments(length(param_types), __MODULE__)

        param_checks =
          param_types
          |> Enum.zip(clean_params)
          |> Enum.with_index()
          |> Enum.flat_map(fn {{param_type, clean_param}, index} ->
            param_check_code(param_type, clean_param, index)
          end)

        return_code_check =
          TypeCheck.Protocols.ToCheck.to_check(return_type, Macro.var(:result, nil))

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
                         %{index: index, problem: problem}, unquote(clean_params)},
                        []
                      }
            end
          end
        end
    end
  end

  def param_check_code(param_type, clean_param, index) do
    impl = TypeCheck.Protocols.ToCheck.to_check(param_type, clean_param)

    quote generated: true, location: :keep do
      [
        {{:ok, _bindings, altered_param}, _index, _param_type} <-
          {unquote(impl), unquote(index), unquote(Macro.escape(param_type))},
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

        %{param_types: nil, return_type: return_type} ->
          inspected_return_type = TypeCheck.Protocols.Inspect.inspect(return_type, opts)

          "(..."
          |> Inspect.Algebra.color(:builtin_type, opts)
          |> Inspect.Algebra.glue(Inspect.Algebra.color("->", :builtin_type, opts))
          |> Inspect.Algebra.glue(inspected_return_type)
          |> Inspect.Algebra.concat(Inspect.Algebra.color(")", :builtin_type, opts))

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

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        case s do
          %{param_types: nil, return_type: result_type} ->
            {StreamData.positive_integer(), StreamData.positive_integer()}
            |> StreamData.bind(fn {arity, seed} ->
              create_wrapper(result_type, arity, seed)
            end)

          %{param_types: param_types, return_type: result_type} when is_list(param_types) ->
            arity = length(param_types)

            StreamData.positive_integer()
            |> StreamData.bind(fn seed ->
              create_wrapper(result_type, arity, seed)
            end)
        end
      end

      defp create_wrapper(result_type, arity, hash_seed) do
        clean_params = Macro.generate_arguments(arity, __MODULE__)

        wrapper_ast =
          quote do
            fn unquote_splicing(clean_params) ->
              persistent_seed = :erlang.phash2(unquote(clean_params), unquote(hash_seed))

              unquote(Macro.escape(result_type))
              |> TypeCheck.Protocols.ToStreamData.to_gen()
              |> StreamData.seeded(persistent_seed)
              |> Enum.take(1)
              |> List.first()
            end
          end

        {fun, _} = Code.eval_quoted(wrapper_ast)
        StreamData.constant(fun)
      end
    end
  end
end
