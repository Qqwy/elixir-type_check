defmodule TypeCheck.DefaultOverrides.Inspect.Opts do
  use TypeCheck
  alias TypeCheck.DefaultOverrides.Inspect
  alias TypeCheck.DefaultOverrides.IO

  @type! color_key() :: atom()

  @type! t() :: %Elixir.Inspect.Opts{
           base: :decimal | :binary | :hex | :octal,
           binaries: :infer | :as_binaries | :as_strings,
           char_lists: :infer | :as_lists | :as_char_lists,
           charlists: :infer | :as_lists | :as_charlists,
           custom_options: keyword(),
           inspect_fun: (any(), t() -> Inspect.Algebra.t()),
           limit: non_neg_integer() | :infinity,
           pretty: boolean(),
           printable_limit: non_neg_integer() | :infinity,
           safe: boolean(),
           structs: boolean(),
           syntax_colors: [{color_key(), IO.ANSI.ansidata()}],
           syntax_colors: [{color_key(), any()}],
           width: non_neg_integer() | :infinity
         }
end
