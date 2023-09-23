defmodule PhxGenOidcc.MixProject do
  use Mix.Project

  def project do
    [
      app: :phx_gen_oidcc,
      version: "0.1.0-rc.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Phx Gen Oidcc",
      source_url: "https://github.com/erlef/phx_gen_oidcc",
      docs: &docs/0,
      description: """
      Plug Integration for the oidcc OpenID Connect Library
      """,
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_apps: [:mix]],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test,
        "coveralls.multiple": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package() do
    [
      maintainers: ["Jonatan Männchen"],
      files: [
        "lib",
        "LICENSE*",
        "mix.exs",
        "README*",
        "priv/templates"
      ],
      licenses: ["Apache-2.0"],
      links: %{"Github" => "https://github.com/erlef/phx_gen_oidcc"}
    ]
  end

  defp docs do
    {ref, 0} = System.cmd("git", ["rev-parse", "--verify", "--quiet", "HEAD"])

    [
      main: "readme",
      source_ref: ref,
      extras: ["README.md"],
      logo: "assets/logo.svg",
      assets: "assets"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:sourceror, "~> 0.13.0"},
      {:briefly, "~> 0.4.1", only: :test},
      {:phx_new, "~> 1.7", only: :test, runtime: false},
      {:phoenix, "~> 1.7"},
      {:ex_doc, "~> 0.29.4", only: :dev, runtime: false},
      {:excoveralls, "~> 0.17.1", only: :test, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false}
    ]
  end
end
