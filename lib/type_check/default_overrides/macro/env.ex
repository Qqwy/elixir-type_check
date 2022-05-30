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

  @typep! tracers() :: [module()]

  @type! variable() :: {atom(), atom() | term()}

  # the :versioned_vars field was introduced in v1.13.0
  # and :contextual_vars and :current_vars, :prematch_vars disappeared.
  if Version.compare(System.version(), "1.13.0") == :lt do
    @typep! var_type() :: :term
    @typep! var_version() :: non_neg_integer()

    @typep! current_vars() ::
    {%{optional(variable()) => {var_version(), var_type()}},
     %{optional(variable()) => {var_version(), var_type()}} | false}
    @typep! contextual_vars() :: [atom()]

    @typep! prematch_vars() ::
    {%{optional(variable()) => {var_version(), var_type()}},
     non_neg_integer()}
    | :warn
    | :raise
    | :pin
    | :apply

    @typep! unused_vars() ::
    {%{optional({atom(), var_version()}) => non_neg_integer() | false},
     non_neg_integer()}

    @typep! vars() :: [variable()]

    @type! t() :: %Macro.Env{
      aliases: aliases(),
      context: context(),
      context_modules: context_modules(),
      contextual_vars: contextual_vars(),
      current_vars: current_vars(),
      file: file(),
      function: name_arity() | nil,
      functions: functions(),
      lexical_tracker: lexical_tracker(),
      line: line(),
      macro_aliases: macro_aliases(),
      macros: macros(),
      module: module(),
      prematch_vars: prematch_vars(),
      unused_vars: unused_vars(),
      requires: requires(),
      tracers: tracers(),
      vars: vars()
    }
  else

    @typep! versioned_vars() :: %{
      optional(variable()) => var_version :: non_neg_integer()
    }

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
  end
end
