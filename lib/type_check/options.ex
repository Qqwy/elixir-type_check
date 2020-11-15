defmodule TypeCheck.Options do
  @moduledoc """
  Defines the options that TypeCheck supports on calls to `use TypeCheck`.


  """

  @type mfa() :: {atom(), atom(), non_neg_integer()}
  @type type_override() :: {(... -> any()), (... -> any())}

  @type t :: %__MODULE__{
    specs: TypeCheck.Options.Spec.t(),
    overrides: list(type_override())
  }

  defstruct [spec: %TypeCheck.Options.Spec{}, overrides: []]

  def new() do
    %__MODULE__{}
  end

  def new(enum) do
    spec = TypeCheck.Options.Spec.new(enum[:spec])
    overrides = check_overrides!(enum[:overrides])
    %__MODULE__{spec: spec, overrides: overrides}
  end

  def check_overrides!(overrides) do
    overrides
    |> Enum.each(fn {k, v} ->
      ensure_external_function!(k)
      ensure_external_function!(v)
    end)

    overrides
  end

  defp ensure_external_function!(fun) when is_function(fun) do
    case Function.info(fun, :type) do
      {:type, :external} ->
        :ok
      _other ->
        raise "Error while parsing TypeCheck overides: #{inspect(fun)} is not an external function of the format `&Module.function/arity`!"
    end
  end
  defp ensure_external_function!(fun) do
    raise "Error while parsing TypeCheck overides: #{inspect(fun)} is not a function!"
  end
end
