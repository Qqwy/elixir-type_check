defmodule TypespecGenerationExample do
  @moduledoc """
  Module used for the regression test of issue #139
  about generation of proper typespecs from recursive type definitions
  where `lazy` and `|` intermingle.
  """
  use TypeCheck

  @type! t() :: lazy(t(true | false))
  @type! t(value) :: {:value, value} | {:t, t()}
end
