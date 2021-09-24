defmodule TypeCheck.Options.DefaultOverrides.NaiveDateTime do
  alias TypeCheck.Options.DefaultOverrides.Calendar
  use TypeCheck
  @type! t() :: %Elixir.NaiveDateTime{
    calendar: Calendar.calendar(),
    day: Calendar.day(),
    hour: Calendar.hour(),
    microsecond: Calendar.microsecond(),
    minute: Calendar.minute(),
    month: Calendar.month(),
    second: Calendar.second(),
    year: Calendar.year()
  }
end
