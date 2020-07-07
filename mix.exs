defmodule TypeCheck.MixProject do
  use Mix.Project

  @source_url "https://github.com/Qqwy/elixir-type_check"

  def project do
    [
      app: :type_check,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      name: "TypeCheck",
      package: package(),
      source_url: @source_url,
      homepage_url: "https://github.com/Qqwy/elixir-type_check",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :stream_data]
    ]
  end

  defp description do
    """
    Fast and flexible runtime type-checking:      Type checks are optimized by the compiler and types can be composed, re-used and turned into Property-testing generators. TypeCheck also focuses on showing understandable messages on typecheck-failures.
    """
  end

  defp package do
    [
      name: :type_check,
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Wiebe-Marten Wijnja/Qqwy"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:stream_data, "~> 0.5.0", optional: true},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "media/type_check_logo_icon_flat_small.svg",
      extras: ["README.md"],
      # main: "TypeCheck",
      groups_for_modules: [
        "Main": [TypeCheck, TypeCheck.Macros, TypeCheck.Type, TypeCheck.Spec],
        "Errors and Formatting them": ~r"^TypeCheck.TypeError",
        "Property Testing": ~r"^TypeCheck.Type.StreamData",
        "Builtin Types": ~r"^TypeCheck.Builtin",
        "Other": ~r"^.*"
      ],
      nest_modules_by_prefix: [TypeCheck.Builtin, TypeCheck.TypeError],
      groups_for_functions: [
        "Built-in Elixir types": &(&1[:typekind] == :builtin),
        "Extensions": &(&1[:typekind] == :extension),
      ]
    ]
  end
end
