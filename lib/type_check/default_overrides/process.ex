defmodule TypeCheck.DefaultOverrides.Process do
  use TypeCheck

  @type! dest() ::
           pid()
           | port()
           | (registered_name :: atom())
           | {registered_name :: atom(), node()}

  @typep! heap_size() ::
            non_neg_integer()
            | %{size: non_neg_integer(), kill: boolean(), error_logger: boolean()}

  @typep! monitor_option() ::
            list(
              {:alias, :explicit_unalias | :demonitor | :reply_demonitor}
              | {:tag, term()}
            )

  # @typep! priority_level() :: :low | :normal | :high | :max

  @type! spawn_opt() ::
           :link
           | :monitor
           | {:monitor, monitor_option()}
           | {:priority, :low | :normal | :high}
           | {:fullsweep_after, non_neg_integer()}
           | {:min_heap_size, non_neg_integer()}
           | {:min_bin_vheap_size, non_neg_integer()}
           | {:max_heap_size, heap_size()}
           | {:message_queue_data, :off_heap | :on_heap}

  @type! spawn_opts() :: [spawn_opt()]
end
