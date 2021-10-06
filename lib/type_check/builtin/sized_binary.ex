defmodule TypeCheck.Builtin.SizedBinary do
  defstruct [:prefix_size, :unit_size]

  use TypeCheck

  @type! t :: %__MODULE__{prefix_size: non_neg_integer(), unit_size: nil | 1..256}
  @type! problem_tuple ::
    {t(), :no_match, %{}, any()}
  | {t(), :wrong_size, %{}, any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote generated: true, location: :keep do
        # TODO
        {:ok, []}
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(s, opts) do
      cond do
        s.unit_size == nil ->
          "<<_::#{s.prefix_size}>>"
        s.prefix_size == 0 ->
          "<<_::_*#{s.unit_size}>>"
        true ->
          "<<_::#{s.prefix_size}, _*#{s.unit_size}>>"
      end
      |> Inspect.Algebra.color(:binary, opts)
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(s) do
        # TODO
        raise "TODO"
      end
    end
  end
end
