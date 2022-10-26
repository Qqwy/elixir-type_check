defmodule TypeCheck.DefaultOverrides.Application do
  use TypeCheck
  @type! app() :: atom()

  @type! application_key() ::
           :start_phases
           | :mod
           | :applications
           | :optional_applications
           | :included_applications
           | :registered
           | :maxT
           | :maxP
           | :modules
           | :vsn
           | :id
           | :description

  @type! key() :: atom()

  @type! restart_type() :: :permanent | :transient | :temporary

  @type! start_type() :: :normal | {:takeover, node()} | {:failover, node()}

  @type! state() :: term()

  @type! value() :: term()
end
