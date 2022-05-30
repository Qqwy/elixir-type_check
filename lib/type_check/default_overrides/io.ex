defmodule TypeCheck.DefaultOverrides.IO do
  alias TypeCheck.DefaultOverrides.String
  use TypeCheck

  @type! chardata() :: String.t() | maybe_improper_list(char() | chardata(), String.t() | [])

  @type! device() :: atom() | pid()

  @type! nodata() :: {:error, term()} | :eof
end
