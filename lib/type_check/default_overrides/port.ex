defmodule TypeCheck.DefaultOverrides.Port do
  use TypeCheck

  @type! name() ::
           {:spawn, charlist() | binary()}
           | {:spawn_driver, charlist() | binary()}
           | {:spawn_executable, charlist() | atom()}
           | {:fd, non_neg_integer(), non_neg_integer()}
end
