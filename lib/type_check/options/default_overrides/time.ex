defmodule TypeCheck.Options.DefaultOverrides.Time do
  alias TypeCheck.Options.DefaultOverrides.Calendar
  use TypeCheck
  @type! t() :: %Elixir.Time{
    calendar: Calendar.calendar(),
    hour: Calendar.hour(),
    microsecond: Calendar.microsecond(),
    minute: Calendar.minute(),
    second: Calendar.second()
  }
end
