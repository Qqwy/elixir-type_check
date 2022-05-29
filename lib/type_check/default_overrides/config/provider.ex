defmodule TypeCheck.DefaultOverrides.Config.Provider do
  use TypeCheck

  @type! config() :: keyword()

  @type! config_path() :: {:system, binary(), binary()} | binary()

  @type! state() :: term()
end
