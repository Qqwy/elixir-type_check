defmodule TypeCheck.DefaultOverrides.Calendar do
  alias __MODULE__
  alias TypeCheck.DefaultOverrides.String

  use TypeCheck

  import TypeCheck.Type.StreamData
  @type! calendar() :: wrap_with_gen(module(), &Calendar.calendar_gen/0)

  # Since Elixir only ships with Calendar.ISO
  # use only that one for data generation
  if Code.ensure_loaded?(StreamData) do
    def calendar_gen do
      StreamData.constant(Elixir.Calendar.ISO)
    end
  else
    def calendar_gen do
      raise TypeCheck.CompileError, "This function requires the optional dependency StreamData."
    end
  end

  @type! date() :: %{
           optional(any()) => any(),
           :calendar => calendar(),
           :year => year(),
           :month => month(),
           :day => day()
         }

  @type! datetime() :: %{
           optional(any()) => any(),
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

  @type! naive_datetime() :: %{
           optional(any()) => any(),
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

  @type! time() :: %{
           optional(any()) => any(),
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
