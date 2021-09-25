defmodule SpectestTestExample do
  use TypeCheck

  # Should succeed the spectest
  @spec! behaving_bunny() :: integer()
  def behaving_bunny() do
    100
  end

  # Should fail the spectest (with a TypeError)
  @spec! mischievous_mannequin() :: atom()
  def mischievous_mannequin() do
    42
  end

  defmodule MySpecialError do
    defexception [:message]
  end

  # Should fail the spectest (with an exception)
  @spec! raising_raptor() :: atom()
  def raising_raptor() do
    raise MySpecialError, "Roar!"
    :ok
  end

  # # Sends the current process a message every time it is called
  # # So we can check how often the function is called.
  # @spec! checking_chiuahua() :: atom()
  # def checking_chiuahua() do
  #   send(self(), :woof!)
  #   :ok
  # end

  # Only works when the seed is 42 (and max_runs is 1)
  @spec! picky_pineapple(integer()) :: :ok
  def picky_pineapple(-1) do
    :ok
  end
end
