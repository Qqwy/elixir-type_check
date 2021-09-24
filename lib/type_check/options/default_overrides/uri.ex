defmodule TypeCheck.Options.DefaultOverrides.URI do
  use TypeCheck
  @type! t() :: %Elixir.URI{
    authority: nil | binary(),
    fragment: nil | binary(),
    host: nil | binary(),
    path: nil | binary(),
    # port: nil | :inet.port_number(),
    port: nil | (port_number :: 0..65535),
    query: nil | binary(),
    scheme: nil | binary(),
    userinfo: nil | binary()
  }
end
