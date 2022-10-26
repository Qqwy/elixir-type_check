defmodule TypeCheck.Builtin.PID do
  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {:no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when is_pid(x) ->
            {:ok, [], x}

          _ ->
            {:error, {:no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "pid()"
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        partgen =
          StreamData.integer()
          |> StreamData.map(&abs/1)

        {partgen, partgen, partgen}
        |> StreamData.map(fn {a, b, c} -> IEx.Helpers.pid(a, b, c) end)

      end
    end
  end
end
