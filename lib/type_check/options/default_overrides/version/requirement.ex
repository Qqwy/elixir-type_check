defmodule TypeCheck.Options.DefaultOverrides.Version.Requirement do
  alias TypeCheck.Options.DefaultOverrides.{String, Version}
  use TypeCheck
  @opaque! matchable() ::
  {Version.major(), Version.minor(), Version.patch(), Version.pre(),
   Version.build()}

  @opaque! t() :: %Elixir.Version.Requirement{
    source: String.t(),
    lexed: [atom | matchable()]
  }
end

