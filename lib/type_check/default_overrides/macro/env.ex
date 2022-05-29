defmodule TypeCheck.DefaultOverrides.Macro.Env do
  use TypeCheck

  @typep! aliases() :: [{module(), module()}]

  @type! context() :: :match | :guard | nil

  @type! context_modules() :: [module()]

  @type! file() :: binary()

  @typep! functions() :: [{module(), [name_arity()]}]

  @typep! lexical_tracker() :: pid() | nil

  @type! line() :: non_neg_integer()

  @typep! macro_aliases() :: [{module(), {term(), module()}}]

  @typep! macros() :: [{module(), [name_arity()]}]

  @type! name_arity() :: {atom(), arity()}

  @typep! requires() :: [module()]

  @type! t() :: %Macro.Env{
    aliases: aliases(),
    context: context(),
    context_modules: context_modules(),
    file: file(),
    function: name_arity() | nil,
    functions: functions(),
    lexical_tracker: lexical_tracker(),
    line: line(),
    macro_aliases: macro_aliases(),
    macros: macros(),
    module: module(),
    requires: requires(),
    tracers: tracers(),
    versioned_vars: versioned_vars()
  }

  @typep! tracers() :: [module()]

  @type! variable() :: {atom(), atom() | term()}

  @typep! versioned_vars() :: %{
    optional(variable()) => var_version :: non_neg_integer()
  }
end
