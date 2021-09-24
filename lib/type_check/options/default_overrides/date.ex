defmodule TypeCheck.Options.DefaultOverrides.Date do
  alias TypeCheck.Options.DefaultOverrides.Calendar
  use TypeCheck
  @type! t() :: %Elixir.Date{
    calendar: Calendar.calendar(),
    day: Calendar.day(),
    month: Calendar.month(),
    year: Calendar.year()
  }
end
