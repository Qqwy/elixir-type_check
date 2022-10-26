defmodule TypeCheck.DefaultOverrides.GenServer do
  use TypeCheck
  alias TypeCheck.DefaultOverrides.Path
  alias TypeCheck.DefaultOverrides.Process

  # TODO
  @type! debug() :: [:trace | :log | :statistics | {:log_to_file, Path.t()}]

  @type! from() :: {pid(), tag :: term()}

  @type! name() :: atom() | {:global, term()} | {:via, module(), term()}

  @type! on_start() ::
           {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}

  @type! option() ::
           {:debug, debug()}
           | {:name, name()}
           | {:timeout, timeout()}
           | {:spawn_opt, [Process.spawn_opt()]}
           | {:hibernate_after, timeout()}

  @type! options() :: [option()]

  @type! server() :: pid() | name() | {atom(), node()}
end
