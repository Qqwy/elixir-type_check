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

  # TODO: c.f. https://github.com/Qqwy/elixir-type_check/issues/116
  # https://github.com/erlang/otp/blob/master/bootstrap/lib/kernel/include/file.hrl#L62
  # -record(file_descriptor,
  #   {module :: module(),     % Module that handles this kind of file
  #    data   :: term()}).     % Module dependent data

  @type! fd :: {:file_descriptor, module :: module(), data :: term()}
  @type! io_device() :: pid() | fd()

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

  @type! posix ::
           :eacces
           | :eagain
           | :ebadf
           | :ebadmsg
           | :ebusy
           | :edeadlk
           | :edeadlock
           | :edquot
           | :eexist
           | :efault
           | :efbig
           | :eftype
           | :eintr
           | :einval
           | :eio
           | :eisdir
           | :eloop
           | :emfile
           | :emlink
           | :emultihop
           | :enametoolong
           | :enfile
           | :enobufs
           | :enodev
           | :enolck
           | :enolink
           | :enoent
           | :enomem
           | :enospc
           | :enosr
           | :enostr
           | :enosys
           | :enotblk
           | :enotdir
           | :enotsup
           | :enxio
           | :eopnotsupp
           | :eoverflow
           | :eperm
           | :epipe
           | :erange
           | :erofs
           | :espipe
           | :esrch
           | :estale
           | :etxtbsy
           | :exdev

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
