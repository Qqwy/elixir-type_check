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
      if s.param_types == nil && s.return_type == %TypeCheck.Builtin.Any{} do
        quote generated: true, location: :keep do
          case unquote(param) do
            x when is_function(x) ->
              {:ok, []}

            _ ->
              {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
          end
        end
      else
        # TODO
        quote generated: true, location: :keep do
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
