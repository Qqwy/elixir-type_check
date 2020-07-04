defmodule TypeCheck.Builtin.Tuple do
  defstruct []
  @moduledoc """
  Checks whether the value is any tuple.

  Returns a problem tuple with the reason `:no_match` otherwise.
  """

  use TypeCheck
  type t :: %__MODULE__{}
  type problem_tuple :: {t(), :no_match, map(), any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_tuple(x) ->
            {:ok, []}
          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  def error_response_type() do
    require TypeCheck.Type
    import TypeCheck.Builtin
    TypeCheck.Type.build({%__MODULE__{}, :no_match, %{}, any()})
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "tuple()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.term()
        |> StreamData.list_of()
        |> StreamData.map(&List.to_tuple(&1))
      end
    end
  end
end
