defmodule TypeCheck.DefaultOverrides.IO.ANSI do
  use TypeCheck
  @type! ansicode() :: atom()

  @type! ansidata() :: ansilist() | ansicode() | binary()

  @type! ansilist() ::
  maybe_improper_list(
    char() | ansicode() | binary() | ansilist(),
    binary() | ansicode() | []
  )
end
