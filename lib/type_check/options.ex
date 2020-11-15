defmodule TypeCheck.Options do
  @moduledoc """
  Defines the options that TypeCheck supports on calls to `use TypeCheck`.


  """

  @type type_override() :: {(... -> any()), (... -> any())}

  @type t :: %__MODULE__{
    check: TypeCheck.Options.Check.t(),
    overrides: list(type_override())
  }

  defstruct [check: %TypeCheck.Options.Check{}, overrides: []]

  def new() do
    %__MODULE__{}
  end

  def new(already_struct = %__MODULE__{}) do
    already_struct
  end

  def new(enum) do
    check = TypeCheck.Options.Check.new(enum[:check] || [])
    raw_overrides = enum[:overrides] || []
    {overrides, _} = Code.eval_quoted(raw_overrides)
    overrides = check_overrides!(overrides)
    %__MODULE__{check: check, overrides: overrides}
  end

  def check_overrides!(overrides) do
    overrides
    |> Enum.map(fn {k, v} ->
      {module_k, function_k, arity_k} = ensure_external_function!(k)
      {module_v, function_v, arity_v} = ensure_external_function!(v)
      if arity_k != arity_v do
        raise "Error while parsing TypeCheck overides: override #{inspect(v)} does not have same arity as original type #{inspect(k)}."
      else
        {
          {module_k, function_k, arity_k},
          {module_v, function_v, arity_v}
        }
      end
    end)
  end

  defp ensure_external_function!(fun) when is_function(fun) do
    case Function.info(fun, :type) do
      {:type, :external} ->
        info = Function.info(fun)
        {info[:module], info[:name], info[:arity]}
      _other ->
        raise "Error while parsing TypeCheck overides: #{inspect(fun)} is not an external function of the format `&Module.function/arity`!"
    end
  end
  defp ensure_external_function!({module, function, arity}) when is_atom(module) and is_atom(function) and arity >= 0 do
    {module, function, arity}
  end
  defp ensure_external_function!(fun) do
    raise "Error while parsing TypeCheck overides: #{inspect(fun)} is not a function!"
  end
end
