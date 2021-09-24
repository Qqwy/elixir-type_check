defmodule TypeCheck.Options.DefaultOverrides.Version do
  alias __MODULE__
  alias TypeCheck.Options.DefaultOverrides.String
  use TypeCheck
  @type! build() :: String.t() | nil

  @type! major() :: non_neg_integer()

  @type! minor() :: non_neg_integer()

  @type! patch() :: non_neg_integer()

  # TODO
  @type! pre() :: [String.t() | non_neg_integer()]

  @type! requirement() :: String.t() | Version.Requirement.t()

  # TODO
  @type! t() :: %Elixir.Version{
    build: build(),
    major: major(),
    minor: minor(),
    patch: patch(),
    pre: pre()
  }

  @type! version() :: String.t() | t()
end
