defmodule TypeCheck.Builtin.ImplementsProtocol do
  defstruct [:protocol]

  @moduledoc """
  Checks whether there is a protocol implementation for this value.

  Returns a problem tuple with the reason `:no_match` otherwise.
  """

  use TypeCheck
  @type! t :: %__MODULE__{protocol: module()}
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
      "impl(#{inspect(s.protocol)})"
      |> Inspect.Algebra.color(:builtin_type, opts)
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
            |> Enum.map(&stream_data_impl(s.protocol, &1))
            |> Enum.filter(fn val -> match?({:ok, _}, val) end)
            |> Enum.map(fn {:ok, val} -> val end)
            |> StreamData.one_of()
        end
      end

      ## 'exceptional' overrides for common protocols
      ## that have strings attached

      # A number of protocols are implemented for BitString
      # but actually raise for bitstring which is not a proper binary
      def stream_data_impl(protocol, BitString) when protocol in [String.Chars, List.Chars] do
        {:ok, StreamData.binary()}
      end

      # Lists can only turned into binaries/charlists
      # if they themselves are charlists
      def stream_data_impl(protocol, List) when protocol in [String.Chars, List.Chars] do
        charlist_gen =
          StreamData.string(:ascii)
          |> StreamData.map(&to_charlist/1)
        {:ok, charlist_gen}
      end

      # Refrain from BitString implementation of Collectable,
      # as it is (1) only implemented for binaries
      # and (2) only accepts as elements other binaries or charlists,
      # so it is a bad candidate for functions checking
      # filling values into 'arbitrary collectables'.
      def stream_data_impl(Collectable, BitString) do
        {:error, :misbehaving_impl}
      end

      # non-empty lists are deprecated for the Collectable protocol
      def stream_data_impl(Collectable, List) do
        {:ok, StreamData.constant([])}
      end

      # 'general' case
      def stream_data_impl(_protocol, module) do
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
          Range ->
            # Note: These are _literal_ range-structs;
            res =
              {StreamData.integer(), StreamData.integer()}
              |> StreamData.bind(fn {a, b} ->
                StreamData.constant(Kernel.".."(min(a, b), max(a, b)))
              end)
            {:ok, res}
          Function ->
            {:error, :not_implemented_yet}
          _ ->
            try do
              {:consolidated, _to_streamdata_impls} = TypeCheck.Protocols.ToStreamData.__protocol__(:impls)
              cond do
                  # If module contains a `@type! t :: ...`
                function_exported?(module, :t, 0) ->
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
            rescue _ ->
                # Skip all implementations that raise an error when invoked like this.
                {:error, :no_impl}
            end
        end
      end
    end
  end
end
