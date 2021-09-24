defmodule TypeCheck.Options.DefaultOverrides.Version.Requirement do
  alias TypeCheck.Options.DefaultOverrides.{String, Version}
  use TypeCheck
  @opaque! matchable() ::
  {Version.major(), Version.minor(), Version.patch(), Version.pre(),
   Version.build()}

  if Elixir.Version.compare(System.version(), "1.11.0") == :lt do
    @opaque! t() :: %Elixir.Version.Requirement{
      source: String.t(),
    }

  else
    @opaque! t() :: %Elixir.Version.Requirement{
      source: String.t(),
      lexed: [atom | matchable()]
    }
  end
end

