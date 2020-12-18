defmodule TypeCheck.Builtin.ImplementsProtocol do
  defstruct [:protocol]

  @moduledoc """
  Checks whether there is a protocol implementation for this value.

  Returns a problem tuple with the reason `:no_match` otherwise.
  """

  use TypeCheck
  @type! t :: %TypeCheck.Builtin.ImplementsProtocol{protocol: module()}
  @type! problem_tuple :: {t(), :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(s.protocol).impl_for(unquote(param)) do
          nil ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
          _ ->
          {:ok, []}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, _opts) do
      "implements_protocol(#{inspect(s.protocol)})"
    end
  end
  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        case s.protocol.__protocol__(:impls) do
          :not_consolidated ->
            raise "values of the type #{inspect(s)} can only be generated when the protocol is consolidated."
          {:consolidated, implementations} ->
            # Extract all implementations that have their own ToStreamData implementation.
            raise "TODO #{inspect(implementations)}"
        end
      end
    end
  end
end
