defmodule TypeCheck.Builtin.Port do
  @moduledoc """
  Type to check whether the given input is any port.

  Check `Port` for more information on ports.

  NOTE: The property testing generator will generate ports of the `cat` binary
  which is a sensible default as it will send back any binaries sent to it exactly.
  However, note that generated ports are not automatically closed.

  """
  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {t(), :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        case unquote(param) do
          x when is_port(x) ->
            {:ok, [], x}

          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "port()"
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        # Ensure every iteration we create a _different_ port
        {}
        |> StreamData.constant()
        |> StreamData.map(fn _ ->
          Port.open({:spawn, "cat"}, [:binary])
        end)
      end
    end
  end
end
