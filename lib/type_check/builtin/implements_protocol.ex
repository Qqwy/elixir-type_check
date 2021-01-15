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
            # raise "TODO #{inspect(implementations)}"
            implementations
            |> Enum.map(&stream_data_impl/1)
            |> Enum.filter(fn val -> match?({:ok, _}, val) end)
            |> Enum.map(fn {:ok, val} -> val end)
            |> StreamData.one_of()
        end
      end

      def stream_data_impl(module) do
        import TypeCheck.Builtin
        alias TypeCheck.Type.StreamData, as: SD
        case module do
          # Generators for builtin (non-struct) protocol types
          Atom -> {:ok, SD.to_gen(atom())}
          Integer -> {:ok, SD.to_gen(integer())}
          Float -> {:ok, SD.to_gen(float())}
          BitString -> {:ok, SD.to_gen(bitstring())}
          List -> {:ok, SD.to_gen(list())}
          Map -> {:ok, SD.to_gen(map())}
          Tuple -> {:ok, SD.to_gen(tuple())}
          Boolean -> {:ok, SD.to_gen(boolean())}
          # Function -> {:ok, SD.to_gen(function())} # function-specs cannot be generated yet.
          _ ->
            {:consolidated, to_streamdata_impls} = TypeCheck.Protocols.ToStreamData.__protocol__(:impls)
            cond do
                # If module contains a `@type! t :: ...`
              function_exported?(module, :t, 0) and module in to_streamdata_impls ->
                res =
                  module.t()
                  |> SD.to_gen()
                {:ok, res}
                # If module contains `new/0`
              function_exported?(module, :new, 0) ->
                res = StreamData.constant(module.new())
                {:ok, res}
              true ->
                {:error, :no_impl}
            end
        end
      end
    end
  end
end
