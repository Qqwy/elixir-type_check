defmodule TypeCheck.Builtin.Float do
  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {:no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when is_float(x) ->
            {:ok, [], x}

          _ ->
            {:error, {:no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "float()"
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.float()
      end
    end
  end
end
