defmodule TypeCheck.DefaultOverrides.IO do
  alias TypeCheck.DefaultOverrides.String, warn: false
  use TypeCheck

  # TODO
  # @autogen_typespec false
  # @type chardata() :: String.t() | maybe_improper_list(char() | chardata(), String.t() | [])
  # @type! chardata() :: String.t() | maybe_improper_list(char() | chardata(), String.t() | [])

  @type! device() :: atom() | pid()

  @type! nodata() :: {:error, term()} | :eof
end
