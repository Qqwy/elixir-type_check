# Used by TypeCheck.Macros tests
# coveralls-ignore-start
defmodule OverrideExample.Original do
  @type t() :: integer()
end

defmodule OverrideExample.Replacement do
  use TypeCheck
  @type! t() :: integer()
end

defmodule OverrideExample do
  use TypeCheck, overrides: [{{OverrideExample.Original, :t, 0}, &OverrideExample.Replacement.t/0}]

  @spec! times_two(OverrideExample.Original.t()) :: integer()
  def times_two(input) do
    input * 2
  end
end
# coveralls-ignore-end
