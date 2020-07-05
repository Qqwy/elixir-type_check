defmodule Example5 do
  def x(value) do
    case(
      case(value) do
        x when not is_tuple(x) ->
          {:error,
           {%{
              __struct__: TypeCheck.Builtin.FixedTuple,
              element_types: [
                %{
                  __struct__: TypeCheck.Builtin.FixedMap,
                  keypairs: [
                    __struct__: %{
                      __struct__: TypeCheck.Builtin.Literal,
                      value: TypeCheck.Builtin.Literal
                    },
                    value: %{
                      __struct__: TypeCheck.Builtin.NamedType,
                      name: :literal,
                      type: %{__struct__: TypeCheck.Builtin.Any}
                    }
                  ]
                },
                %{__struct__: TypeCheck.Builtin.Literal, value: :not_same_value},
                %{
                  __struct__: TypeCheck.Builtin.Map,
                  key_type: %{__struct__: TypeCheck.Builtin.Any},
                  value_type: %{__struct__: TypeCheck.Builtin.Any}
                },
                %{
                  __struct__: TypeCheck.Builtin.NamedType,
                  name: :value,
                  type: %{__struct__: TypeCheck.Builtin.Any}
                }
              ]
            }, :not_a_tuple, %{}, x}}

        x when tuple_size(x) != 4 ->
          {:error,
           {%{
              __struct__: TypeCheck.Builtin.FixedTuple,
              element_types: [
                %{
                  __struct__: TypeCheck.Builtin.FixedMap,
                  keypairs: [
                    __struct__: %{
                      __struct__: TypeCheck.Builtin.Literal,
                      value: TypeCheck.Builtin.Literal
                    },
                    value: %{
                      __struct__: TypeCheck.Builtin.NamedType,
                      name: :literal,
                      type: %{__struct__: TypeCheck.Builtin.Any}
                    }
                  ]
                },
                %{__struct__: TypeCheck.Builtin.Literal, value: :not_same_value},
                %{
                  __struct__: TypeCheck.Builtin.Map,
                  key_type: %{__struct__: TypeCheck.Builtin.Any},
                  value_type: %{__struct__: TypeCheck.Builtin.Any}
                },
                %{
                  __struct__: TypeCheck.Builtin.NamedType,
                  name: :value,
                  type: %{__struct__: TypeCheck.Builtin.Any}
                }
              ]
            }, :different_size, %{expected_size: 4}, x}}

        _ ->
          bindings = []

          with(
            {{:ok, element_bindings}, _index} <-
              {with(
                 {:ok, []} <-
                   if(is_map(elem(value, 0))) do
                     {:ok, []}
                   else
                     {:error,
                      {%{
                         __struct__: TypeCheck.Builtin.FixedMap,
                         keypairs: [
                           __struct__: %{
                             __struct__: TypeCheck.Builtin.Literal,
                             value: TypeCheck.Builtin.Literal
                           },
                           value: %{
                             __struct__: TypeCheck.Builtin.NamedType,
                             name: :literal,
                             type: %{__struct__: TypeCheck.Builtin.Any}
                           }
                         ]
                       }, :not_a_map, %{}, elem(value, 0)}}
                   end,
                 {:ok, []} <-
                   (
                     actual_keys = elem(value, 0) |> Map.keys()

                     case([:__struct__, :value] -- actual_keys) do
                       [] ->
                         {:ok, []}

                       missing_keys ->
                         {:error,
                          {%{
                             __struct__: TypeCheck.Builtin.FixedMap,
                             keypairs: [
                               __struct__: %{
                                 __struct__: TypeCheck.Builtin.Literal,
                                 value: TypeCheck.Builtin.Literal
                               },
                               value: %{
                                 __struct__: TypeCheck.Builtin.NamedType,
                                 name: :literal,
                                 type: %{__struct__: TypeCheck.Builtin.Any}
                               }
                             ]
                           }, :missing_keys, %{keys: missing_keys}, elem(value, 0)}}
                     end
                   ),
                 {:ok, bindings3} <-
                   (
                     bindings = []

                     with(
                       {{:ok, value_bindings}, _key} <-
                         {case(Map.fetch!(elem(value, 0), :__struct__)) do
                            x when x === TypeCheck.Builtin.Literal ->
                              {:ok, []}

                            _ ->
                              {:error,
                               {%{
                                  __struct__: TypeCheck.Builtin.Literal,
                                  value: TypeCheck.Builtin.Literal
                                }, :not_same_value, %{}, Map.fetch!(elem(value, 0), :__struct__)}}
                          end, :__struct__},
                       bindings = value_bindings ++ bindings,
                       {{:ok, value_bindings}, _key} <-
                         {case({:ok, []}) do
                            {:ok, bindings} ->
                              {:ok, [{:literal, Map.fetch!(elem(value, 0), :value)} | bindings]}

                            {:error, problem} ->
                              {:error,
                               {%{
                                  __struct__: TypeCheck.Builtin.NamedType,
                                  name: :literal,
                                  type: %{__struct__: TypeCheck.Builtin.Any}
                                }, :named_type, %{problem: problem},
                                Map.fetch!(elem(value, 0), :value)}}
                          end, :value},
                       bindings = value_bindings ++ bindings
                     ) do
                       {:ok, bindings}
                     else
                       {{:error, error}, key} ->
                         {:error,
                          {%{
                             __struct__: TypeCheck.Builtin.FixedMap,
                             keypairs: [
                               __struct__: %{
                                 __struct__: TypeCheck.Builtin.Literal,
                                 value: TypeCheck.Builtin.Literal
                               },
                               value: %{
                                 __struct__: TypeCheck.Builtin.NamedType,
                                 name: :literal,
                                 type: %{__struct__: TypeCheck.Builtin.Any}
                               }
                             ]
                           }, :value_error, %{problem: error, key: key}, elem(value, 0)}}
                     end
                   )
               ) do
                 {:ok, bindings3}
               end, 0},
            bindings = element_bindings ++ bindings,
            {{:ok, element_bindings}, _index} <-
              {case(elem(value, 1)) do
                 x when x === :not_same_value ->
                   {:ok, []}

                 _ ->
                   {:error,
                    {%{__struct__: TypeCheck.Builtin.Literal, value: :not_same_value},
                     :not_same_value, %{}, elem(value, 1)}}
               end, 1},
            bindings = element_bindings ++ bindings,
            {{:ok, element_bindings}, _index} <-
              {case(elem(value, 2)) do
                 x when not is_map(x) ->
                   {:error,
                    {%{
                       __struct__: TypeCheck.Builtin.Map,
                       key_type: %{__struct__: TypeCheck.Builtin.Any},
                       value_type: %{__struct__: TypeCheck.Builtin.Any}
                     }, :not_a_map, %{}, elem(value, 2)}}

                 _ ->
                   :ok
               end, 2},
            bindings = element_bindings ++ bindings,
            {{:ok, element_bindings}, _index} <-
              {case({:ok, []}) do
                 {:ok, bindings} ->
                   {:ok, [{:value, elem(value, 3)} | bindings]}

                 {:error, problem} ->
                   {:error,
                    {%{
                       __struct__: TypeCheck.Builtin.NamedType,
                       name: :value,
                       type: %{__struct__: TypeCheck.Builtin.Any}
                     }, :named_type, %{problem: problem}, elem(value, 3)}}
               end, 3},
            bindings = element_bindings ++ bindings
          ) do
            {:ok, bindings}
          else
            {{:error, error}, index} ->
              {:error,
               {%{
                  __struct__: TypeCheck.Builtin.FixedTuple,
                  element_types: [
                    %{
                      __struct__: TypeCheck.Builtin.FixedMap,
                      keypairs: [
                        __struct__: %{
                          __struct__: TypeCheck.Builtin.Literal,
                          value: TypeCheck.Builtin.Literal
                        },
                        value: %{
                          __struct__: TypeCheck.Builtin.NamedType,
                          name: :literal,
                          type: %{__struct__: TypeCheck.Builtin.Any}
                        }
                      ]
                    },
                    %{__struct__: TypeCheck.Builtin.Literal, value: :not_same_value},
                    %{
                      __struct__: TypeCheck.Builtin.Map,
                      key_type: %{__struct__: TypeCheck.Builtin.Any},
                      value_type: %{__struct__: TypeCheck.Builtin.Any}
                    },
                    %{
                      __struct__: TypeCheck.Builtin.NamedType,
                      name: :value,
                      type: %{__struct__: TypeCheck.Builtin.Any}
                    }
                  ]
                }, :element_error, %{problem: error, index: index}, value}}
          end
      end
    ) do
      {:ok, bindings} ->
        bindings_map = Enum.into(bindings, %{})
        %{literal: literal, value: value} = bindings_map

        if(literal != value) do
          {:ok, bindings}
        else
          {:error,
           {%{
              __struct__: TypeCheck.Builtin.Guarded,
              guard: {:!=, [line: 6], [{:literal, [line: 6], nil}, {:value, [line: 6], nil}]},
              type: %{
                __struct__: TypeCheck.Builtin.FixedTuple,
                element_types: [
                  %{
                    __struct__: TypeCheck.Builtin.FixedMap,
                    keypairs: [
                      __struct__: %{
                        __struct__: TypeCheck.Builtin.Literal,
                        value: TypeCheck.Builtin.Literal
                      },
                      value: %{
                        __struct__: TypeCheck.Builtin.NamedType,
                        name: :literal,
                        type: %{__struct__: TypeCheck.Builtin.Any}
                      }
                    ]
                  },
                  %{__struct__: TypeCheck.Builtin.Literal, value: :not_same_value},
                  %{
                    __struct__: TypeCheck.Builtin.Map,
                    key_type: %{__struct__: TypeCheck.Builtin.Any},
                    value_type: %{__struct__: TypeCheck.Builtin.Any}
                  },
                  %{
                    __struct__: TypeCheck.Builtin.NamedType,
                    name: :value,
                    type: %{__struct__: TypeCheck.Builtin.Any}
                  }
                ]
              }
            }, :guard_failed, %{bindings: bindings_map}, value}}
        end

      {:error, problem} ->
        {:error,
         {%{
            __struct__: TypeCheck.Builtin.Guarded,
            guard: {:!=, [line: 6], [{:literal, [line: 6], nil}, {:value, [line: 6], nil}]},
            type: %{
              __struct__: TypeCheck.Builtin.FixedTuple,
              element_types: [
                %{
                  __struct__: TypeCheck.Builtin.FixedMap,
                  keypairs: [
                    __struct__: %{
                      __struct__: TypeCheck.Builtin.Literal,
                      value: TypeCheck.Builtin.Literal
                    },
                    value: %{
                      __struct__: TypeCheck.Builtin.NamedType,
                      name: :literal,
                      type: %{__struct__: TypeCheck.Builtin.Any}
                    }
                  ]
                },
                %{__struct__: TypeCheck.Builtin.Literal, value: :not_same_value},
                %{
                  __struct__: TypeCheck.Builtin.Map,
                  key_type: %{__struct__: TypeCheck.Builtin.Any},
                  value_type: %{__struct__: TypeCheck.Builtin.Any}
                },
                %{
                  __struct__: TypeCheck.Builtin.NamedType,
                  name: :value,
                  type: %{__struct__: TypeCheck.Builtin.Any}
                }
              ]
            }
          }, :type_failed, %{problem: problem}, value}}
    end
  end
end
