defmodule TypeCheck.DefaultOverrides.URI do
  use TypeCheck
  @type! port_number() :: 0..65535

  @type! t() :: %Elixir.URI{
    authority: nil | binary(),
    fragment: nil | binary(),
    host: nil | binary(),
    path: nil | binary(),
    # port: nil | :inet.port_number(),
    port: nil | port_number(),
    query: nil | binary(),
    scheme: nil | binary(),
    userinfo: nil | binary()
  }
end
