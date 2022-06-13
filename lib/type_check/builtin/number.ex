defmodule TypeCheck.Builtin.Number do
  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {:no_match, %{}, val :: any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when is_number(x) ->
            {:ok, [], x}

          _ ->
            {:error, {:no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "number()"
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        StreamData.one_of([StreamData.integer(), StreamData.float()])
      end
    end
  end
end
