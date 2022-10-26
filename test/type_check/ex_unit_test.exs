defmodule TypeCheck.ExUnitTest do
  use ExUnit.Case
  use TypeCheck.ExUnit

  describe "spectest uses `:only` option correctly" do
    # Spectest accepts `:only` and this makes it skip all other functions
    spectest(SpectestTestExample, only: [behaving_bunny: 0])
  end

  describe "spectest uses `:except` option correctly" do
    # Spectest accepts `:except` and this makes it skip the mentioned functions
    spectest(SpectestTestExample,
      except: [mischievous_mannequin: 0, raising_raptor: 0, picky_pineapple: 1]
    )
  end

  # This test is nice, but only works on recent Elixir versions.
  unless Elixir.Version.compare(System.version(), "1.12.0") == :lt do
    test "Spectest describes failures correctly" do
      defmodule SpectestTestExampleTest do
        use ExUnit.Case
        use TypeCheck.ExUnit

        spectest(SpectestTestExample, except: [picky_pineapple: 1])
      end

      require ExUnit.CaptureIO

      res =
        ExUnit.CaptureIO.capture_io(fn ->
          ExUnit.configure(colors: [enabled: false])
          ExUnit.run()
        end)

      assert res =~ "3 spectests, 2 failures"

      # mannequin failure is a TypeError:
      assert res =~ "Spectest failed (after 0 successful runs)"
      assert res =~ "Input: SpectestTestExample.mischievous_mannequin()"

      assert res =~ """
             ** (TypeCheck.TypeError) The call to `mischievous_mannequin/0` failed,
                      because the returned result does not adhere to the spec `atom()`.
                      Rather, its value is: `42`.
                      Details:
                        The result of calling `mischievous_mannequin()`
                        does not adhere to spec `mischievous_mannequin() :: atom()`. Reason:
                          Returned result:
                            `42` is not an atom.
             """

      # raptor failure is a MySpecialError:
      assert res =~ "Spectest failed (after 0 successful runs)"
      assert res =~ "Input: SpectestTestExample.raising_raptor()"
      assert res =~ "** (SpectestTestExample.MySpecialError) Roar!"
    end
  end

  describe "spectest uses `:initial_seed` option correctly" do
    seed = 42

    spectest(SpectestTestExample,
      only: [picky_pineapple: 1],
      initial_seed: seed,
      generator: {StreamData, [max_runs: 1]}
    )
  end
end
