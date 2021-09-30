defmodule TypeCheck.DefaultOverrides.DateTime do
  alias TypeCheck.DefaultOverrides.Calendar

  use TypeCheck
  @type! t() :: %Elixir.DateTime{
    calendar: Calendar.calendar(),
    day: Calendar.day(),
    hour: Calendar.hour(),
    microsecond: Calendar.microsecond(),
    minute: Calendar.minute(),
    month: Calendar.month(),
    second: Calendar.second(),
    std_offset: Calendar.std_offset(),
    time_zone: Calendar.time_zone(),
    utc_offset: Calendar.utc_offset(),
    year: Calendar.year(),
    zone_abbr: Calendar.zone_abbr()
  }
end
