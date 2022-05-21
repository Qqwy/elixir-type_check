defmodule TypeCheck.Builtin.Bitstring do
  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {t(), :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: :true, location: :keep do
        case unquote(param) do
          x when is_bitstring(x) ->
            {:ok, [], x}

          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end

    def needs_slow_check?(_), do: false
    def to_check_slow(t, param), do: to_check(t, param)
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "bitstring()"
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.bitstring()
      end
    end
  end
end
