defmodule TypeCheck.DefaultOverrides.Task do
  use TypeCheck

  @type! t() :: %Task{owner: pid(), pid: pid() | nil, ref: reference()}
end
