defmodule User do
  use TypeCheck
  defstruct [:name, :age]

  type t :: %User{name: binary, age: integer}
end

defmodule AgeCheck do
  use TypeCheck

  # @compile {:inline, :"user_older_than? (overridable 1)", 2}
  # @compile {:inline, :"user_older_than? (overridable 1)", 2}
  @compile :inline
  @compile {:inline_size, 48}

  spec user_older_than?(User.t, integer) :: boolean
  def user_older_than?(user, age) do
    user.age >= age
  end
end
