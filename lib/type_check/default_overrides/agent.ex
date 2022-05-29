defmodule TypeCheck.DefaultOverrides.Agent do
  use TypeCheck

  @type! agent() :: pid() | {atom(), node()} | name()

  @type! name() :: atom() | {:global, term()} | {:via, module(), term()}

  @type! on_start() :: {:ok, pid()} | {:error, {:already_started, pid()} | term()}

  @type! state() :: term()
end
