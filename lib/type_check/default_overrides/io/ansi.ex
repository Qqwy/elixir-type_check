defmodule TypeCheck.DefaultOverrides.IO.ANSI do
  use TypeCheck
  @type! ansicode() :: atom()

  # TODO
  # @type! ansidata() :: ansilist() | ansicode() | binary()

  # TODO
  # @type! ansilist() ::
  # maybe_improper_list(
  #   char() | ansicode() | binary() | ansilist(),
  #   binary() | ansicode() | []
  # )
end
