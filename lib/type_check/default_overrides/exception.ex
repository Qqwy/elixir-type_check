defmodule TypeCheck.DefaultOverrides.Exception do
  use TypeCheck
  @type! arity_or_args() :: non_neg_integer() | list()

  @type! kind() :: :error | non_error_kind()

  @type! location() :: keyword()

  @type! non_error_kind() :: :exit | :throw | {:EXIT, pid()}

  @type! stacktrace() :: [stacktrace_entry()]

  @type! stacktrace_entry() ::
  {module(), atom(), arity_or_args(), location()}
  | {(... -> any()), arity_or_args(), location()}

  # TODO
  @type! t() :: %{
    :__struct__ => module(),
    :__exception__ => true,
    # optional(atom()) => any()
  }
end
