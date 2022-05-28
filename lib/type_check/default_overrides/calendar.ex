defmodule TypeCheck.DefaultOverrides.Calendar do
  alias TypeCheck.DefaultOverrides.String

  use TypeCheck

  # Since Elixir only ships with Calendar.ISO
  # use only that one for data generation for now
  @type calendar() :: module()
  @autogen_typespec false
  @type! calendar() :: Elixir.Calendar.ISO

  # TODO
  @type! date() :: %{
    # optional(any()) => any(),
    :calendar => calendar(),
    :year => year(),
    :month => month(),
    :day => day()
  }

  # TODO
  @type! datetime() :: %{
    # optional(any()) => any(),
    :calendar => calendar(),
    :year => year(),
    :month => month(),
    :day => day(),
    :hour => hour(),
    :minute => minute(),
    :second => second(),
    :microsecond => microsecond(),
    :time_zone => time_zone(),
    :zone_abbr => zone_abbr(),
    :utc_offset => utc_offset(),
    :std_offset => std_offset()
  }

  @type! day() :: pos_integer()

  @type! day_fraction() ::
  {parts_in_day :: non_neg_integer(), parts_per_day :: pos_integer()}

  @type! day_of_era() :: {day :: non_neg_integer(), era()}

  @type! day_of_week() :: non_neg_integer()

  @type! era() :: non_neg_integer()

  @type! hour() :: non_neg_integer()

  @type! iso_days() :: {days :: integer(), day_fraction()}

  @type microsecond() :: {non_neg_integer(), non_neg_integer()}
  @autogen_typespec false
  @type! microsecond() :: {0..999_999, 0..6}

  @type! minute() :: non_neg_integer()

  @type! month() :: pos_integer()

  # TODO
  @type! naive_datetime() :: %{
    # optional(any()) => any(),
    :calendar => calendar(),
    :year => year(),
    :month => month(),
    :day => day(),
    :hour => hour(),
    :minute => minute(),
    :second => second(),
    :microsecond => microsecond()
  }

  @type! second() :: non_neg_integer()

  @type! std_offset() :: integer()

  # TODO
  @type! time() :: %{
    # optional(any()) => any(),
    :hour => hour(),
    :minute => minute(),
    :second => second(),
    :microsecond => microsecond()
  }

  @type! time_zone() :: String.t()

  @type! time_zone_database() :: module()

  @type! utc_offset() :: integer()

  @type! week() :: pos_integer()

  @type! year() :: integer()

  @type! zone_abbr() :: String.t()
end
