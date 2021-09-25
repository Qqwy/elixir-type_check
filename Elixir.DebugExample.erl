-file("lib/debug_example.ex", 1).

-module('Elixir.DebugExample').

-compile([no_auto_import, inline,
          {inline_size, 100},
          {inline_size, 1080}]).

-spec stringify(integer()) -> binary().

-export(['__TypeCheck spec for \'stringify/1\'__'/0,
         '__info__'/1,
         stringify/1]).

-spec '__info__'(attributes | compile | functions | macros | md5 |
                 exports_md5 | module | deprecated) ->
                    any().

'__info__'(module) ->
    'Elixir.DebugExample';
'__info__'(functions) ->
    [{'__TypeCheck spec for \'stringify/1\'__', 0}, {stringify, 1}];
'__info__'(macros) ->
    [];
'__info__'(exports_md5) ->
    <<"\026½\002\211ş\214\236\234 EãD\032â@n">>;
'__info__'(Key = attributes) ->
    erlang:get_module_info('Elixir.DebugExample', Key);
'__info__'(Key = compile) ->
    erlang:get_module_info('Elixir.DebugExample', Key);
'__info__'(Key = md5) ->
    erlang:get_module_info('Elixir.DebugExample', Key);
'__info__'(deprecated) ->
    [].

'stringify (overridable 1)'(_val@1) ->
    case _val@1 of
        _@1 when is_binary(_@1) ->
            _@1;
        _@1 ->
            'Elixir.String.Chars':to_string(_@1)
    end.

-file("lib/type_check/spec.ex", 97).

'__TypeCheck spec for \'stringify/1\'__'() ->
    #{'__struct__' => 'Elixir.TypeCheck.Spec',
      name => stringify,
      param_types =>
          [#{'__struct__' => 'Elixir.TypeCheck.Builtin.Integer'}],
      return_type =>
          #{'__struct__' => 'Elixir.TypeCheck.Builtin.Binary'}}.

-file("lib/type_check/spec.ex", 117).

stringify(_@1) ->
    case
        {case _@1 of
             _@7 when is_integer(_@7) ->
                 {ok, []};
             _ ->
                 {error,
                  {#{'__struct__' => 'Elixir.TypeCheck.Builtin.Integer'},
                   no_match,
                   #{},
                   _@1}}
         end,
         0,
         #{'__struct__' => 'Elixir.TypeCheck.Builtin.Integer'}}
    of
        {{ok, _@8}, _@9, _@10} ->
            nil;
        _@2 ->
            case _@2 of
                {{error, _@4}, _@5, _@6} ->
                    error('Elixir.TypeCheck.TypeError':exception({{'Elixir.DebugExample':'__TypeCheck spec for \'stringify/1\'__'(),
                                                                   param_error,
                                                                   #{index =>
                                                                         _@5,
                                                                     problem =>
                                                                         _@4},
                                                                   [_@1]},
                                                                  [{file,
                                                                    <<"/run/"
                                                                      "media"
                                                                      "/qqwy"
                                                                      "/Sere"
                                                                      "ndipi"
                                                                      "ty/Pr"
                                                                      "ogram"
                                                                      "ming/"
                                                                      "Perso"
                                                                      "nal/e"
                                                                      "lixir"
                                                                      "/type"
                                                                      "_chec"
                                                                      "k/lib"
                                                                      "/debu"
                                                                      "g_exa"
                                                                      "mple."
                                                                      "ex">>},
                                                                   {line,
                                                                    1}]}));
                _@3 ->
                    error({with_clause, _@3})
            end
    end,
    _super_result@1 = 'stringify (overridable 1)'(_@1),
    case
        case _super_result@1 of
            _@11 when is_binary(_@11) ->
                {ok, []};
            _ ->
                {error,
                 {#{'__struct__' => 'Elixir.TypeCheck.Builtin.Binary'},
                  no_match,
                  #{},
                  _super_result@1}}
        end
    of
        {ok, _@12} ->
            nil;
        {error, _@13} ->
            error('Elixir.TypeCheck.TypeError':exception({'Elixir.DebugExample':'__TypeCheck spec for \'stringify/1\'__'(),
                                                          return_error,
                                                          #{problem =>
                                                                _@13,
                                                            arguments =>
                                                                [_@1]},
                                                          _super_result@1}))
    end,
    _super_result@1.

