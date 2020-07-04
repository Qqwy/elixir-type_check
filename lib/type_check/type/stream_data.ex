if Code.ensure_loaded?(StreamData) do
  defmodule TypeCheck.Type.StreamData do
    @moduledoc """
    Transforms types to generators.

    This module is only included when the optional dependency
    `:stream_data` is added to your project's dependencies.
    """

    @doc """
    When given a type, it is transformed to a StreamData generator
    that can be used in a property test.

        iex> import TypeCheck.Type.StreamData
        iex> generator = TypeCheck.Type.build({:ok | :error, integer()}) |> to_gen()
        iex> StreamData.seeded(generator, 42) |> Enum.take(10)
        [
        {:ok, -1},
        {:ok, 2},
        {:ok, -2},
        {:ok, -4},
        {:ok, 1},
        {:ok, 1},
        {:ok, 2},
        {:ok, 4},
        {:ok, -7},
        {:ok, 5}
        ]

    """
    def to_gen(type) do
      TypeCheck.Protocols.ToStreamData.to_gen(type)
    end

    def arbitrary_primitive_type_gen do
      import TypeCheck.Builtin
      simple =
        [any(), atom(), binary(), bitstring(), boolean(), float(), function(), integer(), number()]
        |> Enum.map(&Elixir.StreamData.constant/1)

      lit = Elixir.StreamData.term() |> Elixir.StreamData.map(&literal/1)

      choices = [lit | simple]
      Elixir.StreamData.one_of(choices)
    end
  end
end
