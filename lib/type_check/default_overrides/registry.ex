defmodule TypeCheck.DefaultOverrides.Registry do
  use TypeCheck

  @type body() :: [term()]

  @type guard() :: atom() | tuple()

  @type guards() :: [guard()]

  @type key() :: term()

  @type keys() :: :unique | :duplicate

  @type match_pattern() :: atom() | term()

  @type meta_key() :: atom() | tuple()

  @type meta_value() :: term()

  @type registry() :: atom()

  @type spec() :: [{match_pattern(), guards(), body()}]

  @type start_option() ::
          {:keys, keys()}
          | {:name, registry()}
          | {:partitions, pos_integer()}
          | {:listeners, [atom()]}
          | {:meta, [{meta_key(), meta_value()}]}

  @type value() :: term()
end
