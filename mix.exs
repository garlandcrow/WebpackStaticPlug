defmodule SnowpackStatic.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :snowpack_static_plug,
      version: "0.3.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "snowpack_static_plug",
      source_url: "https://github.com/garlandcrow/snowpack_static_plug",
      description: "Phoenix Plug to proxy assets served by the snowpack dev server",
      package: package(),
      docs: [main: "SnowpackStatic.Plug", extras: ["README.md"]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp package do
    [
      maintainers: ["garlandcrow"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/garlandcrow/snowpack_static_plug"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:plug]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.3.0"},
      {:jason, ">= 1.0.0"},
      {:plug, "~> 1.0"},
      {:dialyzex, "~> 1.1.0", only: :dev},
      {:plug_cowboy, "~> 1.0", only: :test},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:bypass, "~> 2.0", only: :test},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test}
    ]
  end
end
