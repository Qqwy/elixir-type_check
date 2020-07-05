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
      choices = primitive_types_list()
      Elixir.StreamData.one_of(choices)
    end

    defp primitive_types_list() do
      import TypeCheck.Builtin
      simple =
        [any(), atom(), binary(), bitstring(), boolean(), float(), function(), integer(), number()]
        |> Enum.map(&Elixir.StreamData.constant/1)

      lit = Elixir.StreamData.term() |> Elixir.StreamData.map(&literal/1)

      [lit | simple]
    end

    def arbitrary_type_gen() do
      # TODO WIP
      StreamData.one_of(primitive_types_list() ++[list_gen(), map_gen(), fixed_list_gen(), fixed_tuple_gen()])
    end

    defp list_gen() do
      lazy_type_gen()
      |> StreamData.map(&TypeCheck.Builtin.list/1)
    end

    defp map_gen() do
      {lazy_type_gen(), lazy_type_gen()}
      |> StreamData.map(fn {key_type, value_type} ->
        TypeCheck.Builtin.map(key_type, value_type)
      end)
    end

    def fixed_list_gen() do
      lazy_type_gen()
      |> StreamData.list_of()
      |> StreamData.map(&TypeCheck.Builtin.fixed_list/1)
    end

    def fixed_tuple_gen() do
      lazy_type_gen()
      |> StreamData.list_of(max_length: 255)
      |> StreamData.map(&TypeCheck.Builtin.fixed_tuple/1)
    end

    defp lazy_type_gen() do
      # Lazily call content generator
      # To prevent infinite expansion recursion
      StreamData.constant({})
      |> StreamData.bind(fn _ ->
        arbitrary_type_gen()
      end)
    end
  end
end
