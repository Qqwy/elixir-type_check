defmodule TypeCheck.DefaultOverrides.Kernel.ParallelCompiler do
  use TypeCheck
  # TODO
  # @type! error() :: {file :: Path.t(), line(), message :: String.t()}

  @type! line() :: non_neg_integer()

  @type! location() :: line() | {line(), column :: non_neg_integer()}

  # TODO
  # @type! warning() :: {file :: Path.t(), location(), message :: String.t()}
end
