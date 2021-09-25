defmodule TypeCheck.DefaultOverrides.File.Stat do
  use TypeCheck
  # TODO
  # @type! t() :: %Elixir.File.Stat{
  #   access: :read | :write | :read_write | :none,
  #   atime: :calendar.datetime() | integer(),
  #   ctime: :calendar.datetime() | integer(),
  #   gid: non_neg_integer(),
  #   inode: non_neg_integer(),
  #   links: non_neg_integer(),
  #   major_device: non_neg_integer(),
  #   minor_device: non_neg_integer(),
  #   mode: non_neg_integer(),
  #   mtime: :calendar.datetime() | integer(),
  #   size: non_neg_integer(),
  #   type: :device | :directory | :regular | :other | :symlink,
  #   uid: non_neg_integer()
  # }
end
