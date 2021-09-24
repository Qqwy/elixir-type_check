defmodule TypeCheck.Options.DefaultOverrides.Module do
  use TypeCheck
  @opaque! def_kind() :: :def | :defp | :defmacro | :defmacrop

  @opaque! definition() :: {atom(), arity()}
end
