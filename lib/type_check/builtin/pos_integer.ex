defmodule TypeCheck.Builtin.PosInteger do
  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {:no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when is_integer(x) and x > 0 ->
            {:ok, [], x}

          _ ->
            {:error, {:no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "pos_integer()"
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.positive_integer()
      end
    end
  end
end
