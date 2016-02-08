defmodule Plugin.Mixfile do
  use Mix.Project
  @version "0.1.0"

  def project do
    [app: :plugin,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:ex_spec, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
     maintainers: ["Roman Heinrich"],
     licenses: ["MIT License"],
     description: "Like Plug, only without web-specific logic and without a typed Conn-datastructure",
     links: %{
       github: "https://github.com/ruby2elixir/plugin",
       docs: "http://hexdocs.pm/plugin/#{@version}/"
     }
    ]
  end
end
