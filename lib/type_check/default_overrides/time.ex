defmodule TypeCheck.DefaultOverrides.Time do
  alias TypeCheck.DefaultOverrides.Calendar
  use TypeCheck
  @type! t() :: %Elixir.Time{
    calendar: Calendar.calendar(),
    hour: Calendar.hour(),
    microsecond: Calendar.microsecond(),
    minute: Calendar.minute(),
    second: Calendar.second()
  }
end
