defmodule TypeCheck.DefaultOverrides.Access do
  use TypeCheck
  @type! access_fun(data, current_value) ::
  get_fun(data) | get_and_update_fun(data, current_value)

  @type! any_container() :: any()

  # TODO
  @type container() :: keyword() | struct() | map()
  @autogen_typespec false
  @type! container() :: keyword() | map()

  # TODO
  @type get_and_update_fun(data, current_value) ::
  (:get_and_update, data, (term() -> term()) ->
    {current_value, new_data :: container()} | :pop)
  @autogen_typespec false
  @type! get_and_update_fun(data, current_value) :: function()

  # TODO
  @type get_fun(data) ::
  (:get, data, (term() -> term()) -> new_data :: container())
  @autogen_typespec false
  @type! get_fun(data) :: function()

  @type! key() :: any()

  @type! nil_container() :: nil

  @type! t() :: container() | nil_container() | any_container()

  @type! value() :: any()
end
