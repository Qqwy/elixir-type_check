defmodule TypeCheck.DefaultOverrides.DynamicSupervisor do
  use TypeCheck
  alias TypeCheck.DefaultOverrides.GenServer

  @type! init_option() ::
  {:strategy, strategy()}
  | {:max_restarts, non_neg_integer()}
  | {:max_seconds, pos_integer()}
  | {:max_children, non_neg_integer() | :infinity}
  | {:extra_arguments, [term()]}

  @type! on_start_child() ::
  {:ok, pid()}
  | {:ok, pid(), info :: term()}
  | :ignore
  | {:error, {:already_started, pid()} | :max_children | term()}

  @type! option() :: GenServer.option()

  @type! strategy() :: :one_for_one

  @type! sup_flags() :: %{
    strategy: strategy(),
    intensity: non_neg_integer(),
    period: pos_integer(),
    max_children: non_neg_integer() | :infinity,
    extra_arguments: [term()]
  }
end
