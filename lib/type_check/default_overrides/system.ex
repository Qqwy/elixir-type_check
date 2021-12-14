defmodule TypeCheck.DefaultOverrides.System do
  use TypeCheck

  @type! signal() ::
           :sigabrt
           | :sigalrm
           | :sigchld
           | :sighup
           | :sigquit
           | :sigstop
           | :sigterm
           | :sigtstp
           | :sigusr1
           | :sigusr2

  @type! time_unit() :: :second | :millisecond | :microsecond | :nanosecond | pos_integer()
end
