defmodule Example do
  use TypeCheck
  # @type! nice_num :: (x :: non_neg_integer() when x != 10)

  @spec! in_magic_range((x :: non_neg_integer() when x != 42)) :: boolean()
  def in_magic_range(val) do
    true
  end
end
