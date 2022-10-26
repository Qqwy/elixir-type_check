defmodule TypeCheck.DefaultOverrides.Calendar.TimeZoneDatabase do
  use TypeCheck

  alias TypeCheck.DefaultOverrides.Calendar

  @type! time_zone_period() :: %{
           optional(any()) => any(),
           utc_offset: Calendar.utc_offset(),
           std_offset: Calendar.std_offset(),
           zone_abbr: Calendar.zone_abbr()
         }

  @type! time_zone_period_limit() :: Calendar.naive_datetime()
end
