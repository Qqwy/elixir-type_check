defmodule TypeCheck.DefaultOverrides.Task.Supervisor do
  use TypeCheck
  alias TypeCheck.DefaultOverrides.DynamicSupervisor

  @type! option() :: DynamicSupervisor.option() | DynamicSupervisor.init_option()
end
