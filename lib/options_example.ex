defmodule OptionsExample do
  use TypeCheck, overrides: [{&Foo.bar/0, &Baz.qux/0}]
end
