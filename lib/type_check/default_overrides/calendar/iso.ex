defmodule TypeCheck.DefaultOverrides.Calendar.ISO do
  use TypeCheck
  @type! bce() :: 0

  @type! ce() :: 1

  @type! day() :: 1..31

  @type! day_of_week() :: 1..7

  @type! day_of_year() :: 1..366

  @type! era() :: bce() | ce()

  @type! hour() :: 0..23

  @type! microsecond() :: {0..999_999, 0..6}

  @type! minute() :: 0..59

  @type! month() :: 1..12

  @type! quarter_of_year() :: 1..4

  @type! second() :: 0..59

  @type! weekday() ::
  :monday
  | :tuesday
  | :wednesday
  | :thursday
  | :friday
  | :saturday
  | :sunday

  @type! year() :: -9999..9999

  @type! year_of_era() :: {1..10000, era()}
end
