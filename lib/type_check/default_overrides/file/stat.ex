defmodule TypeCheck.DefaultOverrides.File.Stat do
  use TypeCheck

  alias Elixir.TypeCheck.DefaultOverrides.Erlang

  @type! t() :: %Elixir.File.Stat{
           access: :read | :write | :read_write | :none,
           atime: Erlang.Calendar.datetime() | integer(),
           ctime: Erlang.Calendar.datetime() | integer(),
           gid: non_neg_integer(),
           inode: non_neg_integer(),
           links: non_neg_integer(),
           major_device: non_neg_integer(),
           minor_device: non_neg_integer(),
           mode: non_neg_integer(),
           mtime: Erlang.Calendar.datetime() | integer(),
           size: non_neg_integer(),
           type: :device | :directory | :regular | :other | :symlink,
           uid: non_neg_integer()
         }
end
