defmodule TypeCheck.DefaultOverrides.Supervisor do
  use TypeCheck

  @type! child() :: pid() | :undefined

  @type! child_spec() :: %{
    :id => atom() | term(),
    :start => {module(), atom(), [term()]},
    optional(:restart) => :permanent | :transient | :temporary,
    optional(:shutdown) => timeout() | :brutal_kill,
    optional(:type) => :worker | :supervisor,
    optional(:modules) => [module()] | :dynamic
  }

  @type! init_option() ::
  {:strategy, strategy()}
  | {:max_restarts, non_neg_integer()}
  | {:max_seconds, pos_integer()}

  @type! name() :: atom() | {:global, term()} | {:via, module(), term()}

  @type! on_start() ::
  {:ok, pid()}
  | :ignore
  | {:error, {:already_started, pid()} | {:shutdown, term()} | term()}

  @type! on_start_child() ::
  {:ok, child()}
  | {:ok, child(), info :: term()}
  | {:error, {:already_started, child()} | :already_present | term()}

  @type! option() :: {:name, name()}

  @type! strategy() :: :one_for_one | :one_for_all | :rest_for_one

  @type! supervisor() :: pid() | name() | {atom(), node()}
end
