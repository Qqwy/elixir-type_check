defmodule TypeCheck.Builtin.None do
  @moduledoc """
  The 'none' type has no inhabitants.
  In other words, no value will typecheck against this type.

  This means that we always return a problem tuple with `:no_match` as reason in its check.

  It also means that the StreamData-generator will not generate any values;
  instead, it will filter away values that would have been produced by `none()`,
  meaning that if you attempt to use `none()` directly in a generator, you might get a `StreamData.FilterTooNarrowError`.
  However, it's still possible to combine it with other types like `:ok | :error | none()` and e.g. use the resulting generator of that.
  """

  defstruct []

  use TypeCheck
  @type! t :: %__MODULE__{}
  @type! problem_tuple :: {t(), :no_match, %{}, val :: any()}

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(s, param) do
      quote do
        {:error, {unquote(Macro.escape(s)), :no_match, %{}, unquote(param)}}
      end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(_, _opts) do
      "none()"
    end
  end

  if Code.ensure_loaded?(StreamData) do
    defimpl TypeCheck.Protocols.ToStreamData do
      def to_gen(_s) do
        "none() cannot directly be used in a generator since no values inhabit this type!"
        |> StreamData.constant()
        |> StreamData.filter(fn _ -> false end, 1_000)
      end
    end
  end
end
