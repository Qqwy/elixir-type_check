defmodule TypeCheck.Options.DefaultOverrides.Date.Range do
  alias TypeCheck.Options.DefaultOverrides.Calendar
  alias TypeCheck.Options.DefaultOverrides.Date
  use TypeCheck
  @opaque! iso_days() :: Calendar.iso_days()

  if Elixir.Version.compare(System.version(), "1.12.0") == :lt do
    @type! t() :: %Elixir.Date.Range{
      first: Date.t(),
      first_in_iso_days: iso_days(),
      last: Date.t(),
      last_in_iso_days: iso_days()
    }
  else
    @type! t() :: %Elixir.Date.Range{
      first: Date.t(),
      first_in_iso_days: iso_days(),
      last: Date.t(),
      last_in_iso_days: iso_days(),
      step: pos_integer() | neg_integer()
    }
  end
end
