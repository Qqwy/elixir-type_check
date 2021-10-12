defmodule TypeCheck.Builtin.Function do
  defstruct [param_types: nil, return_type: %TypeCheck.Builtin.Any{}]

  use TypeCheck
  @opaque! t :: %TypeCheck.Builtin.Function{
    param_types: list(TypeCheck.Type.t() | nil),
    return_type: TypeCheck.Type.t()
  }
  @type! problem_tuple :: {t(), :no_match, %{}, any()} # TODO

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      case s do
        %TypeCheck.Builtin.Function{param_types: nil, return_type: %TypeCheck.Builtin.Any{}} ->
          quote generated: true, location: :keep do
            case unquote(param) do
              x when is_function(x) ->
                {:ok, []}

              _ ->
                {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
            end
          end
        %TypeCheck.Builtin.Function{param_types: nil, return_type: other} ->
          # TODO
          quote generated: true, location: :keep do
            {:ok, []}
          end
        %TypeCheck.Builtin.Function{param_types: param_types, return_type: return_type} ->
          clean_params = Macro.generate_arguments(length(param_types), __MODULE__)
          param_checks =
            clean_params
          |> Enum.zip(param_types)
          |> Enum.map(fn {param, type} ->
            IO.inspect(type, label: :type)
            check = TypeCheck.Protocols.ToCheck.to_check(type, param)
            quote generated: true, location: :keep do
              require TypeCheck
              case unquote(check) do
                {:ok, _bindings} -> :ok
                {:error, other} -> raise TypeCheck.TypeError, other
              end
            end
          end)


          quote generated: true, location: :keep do
            require TypeCheck
            fun = fn unquote_splicing(clean_params) ->
              unquote_splicing(param_checks)
              result = unquote(param).(unquote_splicing(clean_params))
              case TypeCheck.Protocols.ToCheck.to_check(type, result) do
                {:ok, _bindings} -> result
                {:error, other} -> raise TypeCheck.TypeError, other
              end
            end
            send self(), fun
            {:ok, []}
          end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    import Kernel, except: [inspect: 2]
    def inspect(s, opts) do
      case s do
        %TypeCheck.Builtin.Function{param_types: nil, return_type: %TypeCheck.Builtin.Any{}} ->
          "function()"
          |> Inspect.Algebra.color(:builtin_type, opts)
        other ->
          # TODO
          Kernel.inspect(other, structs: false)
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
