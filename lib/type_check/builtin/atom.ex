defmodule TypeCheck.Builtin.Atom do
  defstruct []

  @moduledoc """
  Checks whether the value is any atom.

  Returns a problem tuple with the reason `:no_match` otherwise.
  """

  use TypeCheck
  type t :: %__MODULE__{}
  type problem_tuple :: {t(), :no_match, map(), any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        case unquote(param) do
          x when is_atom(x) ->
            :ok

          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end

    def simple?(_) do
      true
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "atom()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.atom(:alphanumeric)
      end
    end
  end
end
