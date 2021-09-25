defmodule TypeCheck.DefaultOverrides.File do
  use TypeCheck
  @type! encoding_mode() ::
  :utf8
  | {:encoding,
     :latin1
     | :unicode
     | :utf8
     | :utf16
     | :utf32
     | {:utf16, :big | :little}
     | {:utf32, :big | :little}}

  @type! erlang_time() ::
  {{year :: non_neg_integer(), month :: 1..12, day :: 1..31},
   {hour :: 0..23, minute :: 0..59, second :: 0..59}}

  # TODO
  # @type! io_device() :: :file.io_device()

  @type! mode() ::
  :append
  | :binary
  | :charlist
  | :compressed
  | :delayed_write
  | :exclusive
  | :raw
  | :read
  | :read_ahead
  | :sync
  | :write
  | {:read_ahead, pos_integer()}
  | {:delayed_write, non_neg_integer(), non_neg_integer()}
  | encoding_mode()

  # TODO
  # @type! posix() :: :file.posix()

  @type! posix_time() :: integer()

  @type! stat_options() :: [{:time, :local | :universal | :posix}]

  @type! stream_mode() ::
  encoding_mode()
  | :append
  | :compressed
  | :trim_bom
  | {:read_ahead, pos_integer() | false}
  | {:delayed_write, non_neg_integer(), non_neg_integer()}
end
