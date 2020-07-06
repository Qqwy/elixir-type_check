defmodule TypeCheckTest.TypeGuardExample do
  use TypeCheck
  type sorted_pair :: {lower :: number(), higher :: number()} when lower <= higher
end

defmodule TypeCheckTest do
  use ExUnit.Case


  import TypeCheckTest.TypeGuardExample

  doctest TypeCheck

end
