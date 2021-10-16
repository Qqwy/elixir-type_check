defmodule TypeCheck.Builtin.Tuple do
  defstruct []

  @moduledoc """
  Checks whether the value is any tuple.

  Returns a problem tuple with the reason `:no_match` otherwise.
  """

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {t(), :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when is_tuple(x) ->
            {:ok, [], x}

          other ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, other}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "tuple()"
      |> Inspect.Algebra.color(:builtin_type, opts)
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
