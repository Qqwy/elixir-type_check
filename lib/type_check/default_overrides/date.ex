defmodule TypeCheck.DefaultOverrides.Date do
  alias TypeCheck.DefaultOverrides.Calendar
  use TypeCheck
  @type! t() :: %Elixir.Date{
    calendar: Calendar.calendar(),
    day: Calendar.day(),
    month: Calendar.month(),
    year: Calendar.year()
  }
end
