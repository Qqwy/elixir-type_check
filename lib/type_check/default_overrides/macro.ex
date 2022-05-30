defmodule TypeCheck.DefaultOverrides.Macro do
  use TypeCheck

  @type! captured_remote_function() :: (... -> any())

  @type! input() ::
  input_expr()
  | {lazy(input()), lazy(input())}
  | [lazy(input())]
  | atom()
  | number()
  | binary()

  @typep! input_expr() :: {lazy(input_expr()) | atom(), metadata(), atom() | [lazy(input())]}

  @type! metadata() :: keyword()

  @type! output() ::
  output_expr()
  | {lazy(output()), lazy(output())}
  | [lazy(output())]
  | atom()
  | number()
  | binary()
  | captured_remote_function()
  | pid()

  @typep! output_expr() ::
  {lazy(output_expr()) | atom(), metadata(), atom() | [lazy(output())]}

  @type! t() :: input()
end
