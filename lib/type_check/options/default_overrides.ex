defmodule TypeCheck.Options.DefaultOverrides do
  @moduledoc """
  Contains a many common types that can be used as overrides for Elixir's standard library types.
  """
  alias TypeCheck.Options.DefaultOverrides.{
    Access,
    Calendar,
    Date,
    Collectable,
    Enum,
    Enumerable,
    String,
    Version,
    Version.Requirement
  }, warn: false

  # Overrides Erlang's `:binary` module:
  defmodule :"Elixir.TypeCheck.Options.DefaultOverrides.binary" do
    use TypeCheck
    # TODO
    @opaque cp() :: {any(), reference()}
    @autogen_typespec false
    @opaque! cp() :: {'am' | 'bm', term()}

    @opaque! part() :: {start :: non_neg_integer(), length :: integer()}
  end

  defmodule Calendar do
    use TypeCheck
    @type! calendar() :: module()

    @type! date() :: %{
      # optional(any()) => any(),
      :calendar => calendar(),
      :year => year(),
      :month => month(),
      :day => day()
    }

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

    @type! microsecond() :: {non_neg_integer(), non_neg_integer()}

    @type! minute() :: non_neg_integer()

    @type! month() :: pos_integer()

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

  defmodule Date do
    use TypeCheck
    @type! t() :: %Elixir.Date{
      calendar: Calendar.calendar(),
      day: Calendar.day(),
      month: Calendar.month(),
      year: Calendar.year()
    }
  end

  defmodule Date.Range do
    use TypeCheck
    @opaque! iso_days() :: Calendar.iso_days()

    @type! t() :: %Elixir.Date.Range{
      first: Date.t(),
      first_in_iso_days: iso_days(),
      last: Date.t(),
      last_in_iso_days: iso_days(),
      step: pos_integer() | neg_integer()
    }
  end

  defmodule Range do
    use TypeCheck
    @type! limit() :: integer()

    @type! step() :: pos_integer() | neg_integer()

    @type! t() :: %Elixir.Range{first: limit(), last: limit(), step: step()}

    @type! t(first, last) :: %Elixir.Range{first: first, last: last, step: step()}
  end

  defmodule Enumerable do
    use TypeCheck
    @type! acc() :: {:cont, term()} | {:halt, term()} | {:suspend, term()}

    # TODO
    @type continuation() :: (acc() -> result())
    @autogen_typespec false
    @type! continuation() :: function()

    # TODO
    @type reducer() :: (element :: term(), current_acc :: acc() -> updated_acc :: acc())
    @autogen_typespec false
    @type! reducer() :: function()

    @type! result() ::
    {:done, term()}
    | {:halted, term()}
    | {:suspended, term(), continuation()}

    # TODO
    @type slicing_fun() :: (start :: non_neg_integer(), length :: pos_integer() -> [term()])
    @autogen_typespec false
    @type! slicing_fun() :: function()

    @type! t() :: impl(Elixir.Enumerable)
  end

  defmodule Collectable do
    use TypeCheck
    @type! command() :: {:cont, term()} | :done | :halt
    @type! t() :: impl(Elixir.Collectable)
  end

  defmodule Enum do
    use TypeCheck
    @type! acc() :: any()
    @type! default() :: any()
    @type! element() :: any()
    @type! index() :: integer()
    @type! t() :: Enumerable.t()
  end

  defmodule Exception do
    use TypeCheck
    @type! arity_or_args() :: non_neg_integer() | list()

    @type! kind() :: :error | non_error_kind()

    @type! location() :: keyword()

    # TODO
    @type non_error_kind() :: :exit | :throw | {:EXIT, pid()}
    @autogen_typespec false
    @type! non_error_kind() :: :exit | :throw | {:EXIT, term()}

    @type! stacktrace() :: [stacktrace_entry()]

    # TODO
    @type! stacktrace_entry() ::
    {module(), atom(), arity_or_args(), location()}
    | {function(), arity_or_args(), location()}

    # TODO
    @type! t() :: %{
      :__struct__ => module(),
      :__exception__ => true,
      # optional(atom()) => any()
    }
  end

  defmodule Float do
    use TypeCheck
    @type! precision_range() :: 0..15
  end

  defmodule Function do
    use TypeCheck
    @type! information() ::
    :arity
    | :env
    | :index
    | :module
    | :name
    | :new_index
    | :new_uniq
    | :pid
    | :type
    | :uniq
  end

  defmodule Module do
    use TypeCheck
    @opaque! def_kind() :: :def | :defp | :defmacro | :defmacrop

    @opaque! definition() :: {atom(), arity()}
  end

  defmodule Inspect do
    use TypeCheck
    @type! t() :: impl(Elixir.Inspect)
  end

  defmodule MapSet do

  end

  defmodule NaiveDateTime do
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

  defmodule Regex do
    use TypeCheck
    @type! t() :: %Elixir.Regex{
      opts: binary(),
      re_pattern: term(),
      re_version: term(),
      source: binary()
    }
  end

  defmodule String do
    use TypeCheck
    @type! codepoint() :: t()

    @type! grapheme() :: t()

    @type! pattern() :: t() | [t()] | :"Elixir.TypeCheck.Options.DefaultOverrides.binary".cp()
    @type! t() :: binary()
  end

  defmodule Time do
    use TypeCheck
    @type! t() :: %Elixir.Time{
      calendar: Calendar.calendar(),
      hour: Calendar.hour(),
      microsecond: Calendar.microsecond(),
      minute: Calendar.minute(),
      second: Calendar.second()
    }
  end

  defmodule URI do
    use TypeCheck
    @type! t() :: %Elixir.URI{
      authority: nil | binary(),
      fragment: nil | binary(),
      host: nil | binary(),
      path: nil | binary(),
      # port: nil | :inet.port_number(),
      port: nil | (port_number :: 0..65535),
      query: nil | binary(),
      scheme: nil | binary(),
      userinfo: nil | binary()
    }
  end

  defmodule Version.Requirement do
    use TypeCheck
    @opaque! matchable() ::
    {Version.major(), Version.minor(), Version.patch(), Version.pre(),
     Version.build()}

    @opaque! t() :: %Elixir.Version.Requirement{
      source: String.t(),
      lexed: [atom | matchable()]
    }
  end

  defmodule Version do
    use TypeCheck
    @type! build() :: String.t() | nil

    @type! major() :: non_neg_integer()

    @type! minor() :: non_neg_integer()

    @type! patch() :: non_neg_integer()

    # TODO
    @type! pre() :: [String.t() | non_neg_integer()]

    @type! requirement() :: String.t() | Version.Requirement.t()

    # TODO
    @type! t() :: %Elixir.Version{
      build: build(),
      major: major(),
      minor: minor(),
      patch: patch(),
      pre: pre()
    }

    @type! version() :: String.t() | t()
  end
end
