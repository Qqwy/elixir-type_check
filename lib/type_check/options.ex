defmodule TypeCheck.Options do
  @moduledoc """
  Defines the options that TypeCheck supports on calls to `use TypeCheck`.

  Supported options:

  - `:overrides`: A list of overrides for remote types.

  These options are usually specified as passed to `use TypeCheck`,
  although they may also be passed in direct calls to `TypeCheck.conforms/3` (and its variants).

  These options are module-specific and are read/used at compile-time.

  ## The supported options in detail

  ### Overrides:

  The `:overrides` field contains a list of remote types to be overridden by a replacement.
  This is useful to be able to specify TypeCheck-types for types that you do not have control over
  (because they are for instance defined in a library that is not itself using TypeCheck).

  For obvious reasons, using TypeCheck directly should be preferred over overriding types.


  Each of the elements in the `:overrides` list should be written as `{original_type, replacement_type}`.
  Both of these can take the shape of either`&Module.type/arity` or the longer form `{Module, :type, arity}`.

  An example:

  ```
  use TypeCheck, overrides: [
    {&Ecto.Schema.t/0, &MyProject.TypeCheckOverrides.Ecto.Schema.t/0}
  ]
  ```
  """

  @type type_override() :: {(... -> any()), (... -> any())}

  @type t :: %__MODULE__{
    overrides: list(type_override())
  }

  defstruct [overrides: []]

  def new() do
    %__MODULE__{}
  end

  def new(already_struct = %__MODULE__{}) do
    already_struct
  end

  def new(enum) do
    raw_overrides = enum[:overrides] || []
    # {overrides, _} = Code.eval_quoted(raw_overrides)
    overrides = check_overrides!(raw_overrides)
    %__MODULE__{overrides: overrides}
  end

  def check_overrides!(overrides) do
    Enum.map(overrides, &check_override!/1)
  end

  defp check_override!({original, override}) do
    {module_k, function_k, arity_k} = ensure_external_function!(original)
    {module_v, function_v, arity_v} = ensure_external_function!(override)
    if arity_k != arity_v do
      raise "Error while parsing TypeCheck overides: override #{inspect(override)} does not have same arity as original type #{inspect(original)}."
    else
      {
        {module_k, function_k, arity_k},
        {module_v, function_v, arity_v}
      }
    end
  end
  defp check_override!(other) do
    raise ArgumentError, "`check_overrides!` expects a list of two-element tuples `{mfa, mfa}` where `mfa` is either `{Module, function, arity}` or `&Module.function/arity`. However, an element not adhering to the `{mfa, mfa}` format was found: `#{inspect(other)}`."
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
