# Overrides Erlang's `:binary` module:
defmodule Elixir.TypeCheck.DefaultOverrides.Erlang.Calendar do
  use TypeCheck

  @type! date() :: {year(), month(), day()}

  @type! datetime() :: {date(), time()}

  @type! datetime1970() :: {{year1970(), month(), day()}, time()}

  @typep! day() :: 1..31

  # @typep! day_of_year() :: 0..365

  # @typep! daynum() :: 1..7

  @typep! hour() :: 0..23

  # @typep! ldom() :: 28 | 29 | 30 | 31

  @typep! minute() :: 0..59

  @typep! month() :: 1..12

  # @typep! offset() :: [byte()] | (time :: integer())

  # @typep! rfc3339_string() :: [byte(), ...]

  # @typep! rfc3339_time_unit() ::
  # :microsecond | :millisecond | :nanosecond | :second | :native

  @typep! second() :: 0..59

  # @typep! secs_per_day() :: 0..86400

  @type! time() :: {hour(), minute(), second()}

  # @typep! weeknum() :: 1..53

  @typep! year() :: non_neg_integer()

  @typep! year1970() :: 1970..10000

  # @typep! yearweeknum() :: {year(), weeknum()}
end
