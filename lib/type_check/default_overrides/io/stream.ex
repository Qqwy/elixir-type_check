defmodule TypeCheck.DefaultOverrides.IO.Stream do
  use TypeCheck

  @type! t() :: %IO.Stream{device: term(), line_or_bytes: term(), raw: term()}
end
