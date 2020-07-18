# Used by "mix format"
no_parens = [type!: 1, typep!: 1, opaque!: 1, spec!: 1]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: no_parens,
  import_deps: [:stream_data],
  export: [
    locals_without_parens: no_parens
  ]
]
