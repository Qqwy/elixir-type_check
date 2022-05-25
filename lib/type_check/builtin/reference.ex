defmodule TypeCheck.Builtin.Reference do
  @moduledoc """
  Type to check whether the given input is a reference.

  Elixir/Erlang uses references for two use-cases:
  1. As unique identifiers.
  2. To refer to resources created and returned by NIFs (to be passed to other NIFs of the same NIF module).

  The property testing generator will generate arbitrary references using `Kernel.make_ref()`.
  To property-test the second kind of data, you should create your own kind of generator
  that calls the appropriate NIF.
  """
  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {t(), :no_match, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: :true, location: :keep do
        case unquote(param) do
          x when is_reference(x) ->
            {:ok, [], x}
          _ ->
            {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
        end
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, opts) do
      "reference()"
      |> Inspect.Algebra.color(:builtin_type, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        # Ensure every iteration we create a _different_ reference
        StreamData.constant({})
        |> StreamData.map(fn _ -> make_ref() end)
      end
    end
  end
end
