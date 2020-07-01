defmodule Example3 do
  # import TypeCheck.Builtin
  # def hello(x) do
  #   import TypeCheck
  #   conforms!(x, %{a: integer(), b: float()})
  # end
  use TypeCheck

  defmodule User do
    use TypeCheck
    defstruct [:name, :age]

    type t :: %__MODULE__{name: binary(), age: integer()}
  end


  spec is_user_older_than?(User.t, integer()) :: boolean
  def is_user_older_than?(user, age) do
    user.age >= age
  end
end
