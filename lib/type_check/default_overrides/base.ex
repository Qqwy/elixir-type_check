defmodule TypeCheck.DefaultOverrides.Base do
  use TypeCheck

  @type! decode_case() :: :upper | :lower | :mixed

  @type! encode_case() :: :upper | :lower
end
