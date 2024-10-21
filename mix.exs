defmodule TypeCheck.MixProject do
  use Mix.Project

  @source_url "https://github.com/Qqwy/elixir-type_check"

  def project do
    [
      app: :type_check,
      version: "0.13.5",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      name: "TypeCheck",
      package: package(),
      source_url: @source_url,
      homepage_url: "https://github.com/Qqwy/elixir-type_check",
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    case Mix.env() do
      :prod ->
        [
          extra_applications: [:logger, :iex]
        ]

      _ ->
        [
          extra_applications: [:logger, :iex, :stream_data, :credo]
        ]
    end
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  defp description do
    """
    Fast and flexible runtime type-checking: Type checks are optimized by the compiler and types can be composed, re-used and turned into property-testing generators. TypeCheck also focuses on showing understandable messages on typecheck-failures.
    """
  end

  defp package do
    [
      name: :type_check,
      files: [
        "lib",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE",
        "Comparing TypeCheck and Norm.md"
      ],
      maintainers: ["Wiebe-Marten Wijnja/Qqwy"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Used for spectesting and property-tests in general:
      {:stream_data, "~> 0.5.0", optional: true},
      {:credo, "~> 1.5", runtime: false, optional: true},

      # For documentation purposes:
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :bench},
      {:excoveralls, "~> 0.10", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
      {:castore, "~> 1.0"} # <- Dependency of excoveralls required on OTP < 25
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "media/type_check_logo_icon_flat_small.svg",
      extras: [
        "README.md": [title: "Guide/Readme"],
        "CHANGELOG.md": [title: "Changelog"],
        "Type-checking and spec-testing with TypeCheck.md": [title: "Introducing TypeCheck"],
        "Comparing TypeCheck and Elixir Typespecs.md": [title: "Comparison to Plain Typespecs"],
        "Comparing TypeCheck and Norm.md": []
      ],
      # main: "TypeCheck",
      groups_for_modules: [
        Main: [
          TypeCheck,
          TypeCheck.Macros,
          TypeCheck.Type,
          TypeCheck.Spec,
          TypeCheck.Options,
          TypeCheck.ExUnit,
          TypeCheck.External,
          TypeCheck.Defstruct
        ],
        "Errors and Formatting them": ~r"^TypeCheck.TypeError",
        "Property Testing": ~r"^TypeCheck.Type.StreamData",
        "Builtin Types": ~r"^TypeCheck.Builtin",
        "Standard Library overrides": ~r"^TypeCheck.DefaultOverrides",
        Other: ~r"^.*"
      ],
      nest_modules_by_prefix: [TypeCheck.Builtin, TypeCheck.TypeError, TypeCheck.DefaultOverrides],
      groups_for_functions: [
        "Built-in Elixir types": &(&1[:typekind] == :builtin),
        Extensions: &(&1[:typekind] == :extension)
      ]
    ]
  end
end
