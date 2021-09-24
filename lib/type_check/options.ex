defmodule TypeCheck.Options do
  import TypeCheck.Internals.Bootstrap.Macros
  @moduledoc """
  Defines the options that TypeCheck supports on calls to `use TypeCheck`.

  Supported options:

  - `:overrides`: A list of overrides for remote types. (default: `[]`)
  - `:default_overrides`: A boolean. If false, will not include any of the overrides of the types of Elixir's standard library (c.f. `TypeCheck.Options.DefaultOverrides.default_overrides/0`). (default: `true`)
  - `:debug`: When true, will (at compile-time) print the generated TypeCheck-checking code. (default: `false`)

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

  ### Debugging

  Passing the option `debug: true` will at compile-time print the generated code
  for all added `@spec`s, as well as `TypeCheck.conforms/3`/`TypeCheck.conforms?/3`/`TypeCheck.conforms!/3` calls.
  ```
  """

  if_recompiling? do
    use TypeCheck

    @type! remote_type() :: mfa() | function

    @typedoc """
    An extra check is performed to ensure that the original type
    and the replacement type have the same arity.
    """
    @type! type_override :: {original :: remote_type(), replacement :: remote_type()}
    @type! type_overrides :: list(type_override())

    @type! t :: %TypeCheck.Options{
      overrides: type_overrides(),
      default_overrides: boolean(),
      debug: boolean()
    }
  else
    @type remote_type() :: mfa | function
    @type type_override :: {remote_type(), remote_type()}

    @type t :: %TypeCheck.Options{
      overrides: list(type_override()),
      default_overrides: boolean(),
      debug: boolean()
    }
  end

  defstruct [overrides: [], default_overrides: true, debug: false]

  def new() do
    %__MODULE__{overrides: default_overrides()}
  end

  def new(already_struct = %__MODULE__{}) do
    already_struct
  end

  if_recompiling? do
    @spec! new(enum :: any()) :: t()
  end
  def new(enum) do
    raw_overrides = enum[:overrides] || []
    debug = enum[:debug] || false

    overrides = check_overrides!(raw_overrides)
    overrides =
      if Access.get(enum, :default_overrides, true) do
        overrides ++ default_overrides()
      else
        overrides
      end

    %__MODULE__{overrides: overrides, debug: debug}
  end

  if_recompiling? do
    @spec! check_overrides!(overrides :: type_overrides()) :: type_overrides()
  end
  def check_overrides!(overrides) do
    Enum.map(overrides, &check_override!/1)
  end

  defp default_overrides() do
      case Code.ensure_loaded(TypeCheck.Options.DefaultOverrides) do
        {:error, _problem} -> []
        {:module, _} -> apply(TypeCheck.Options.DefaultOverrides, :default_overrides, [])
      end
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
