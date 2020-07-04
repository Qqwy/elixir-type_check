defmodule TypeCheck.Builtin.Function do
  defstruct []

  use TypeCheck
  type problem_tuple_type :: {:error, %__MODULE__{}, :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_function(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "function()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        raise "Not implemented yet. PRs are welcome!"
      end
    end
  end
end
