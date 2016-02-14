defmodule NatSet.Mixfile do
  use Mix.Project

  @version "0.0.1"
  @github_url "https://github.com/hilverd/nat-set-elixir"

  def project do
    [app: :nat_set,
     version: @version,
     elixir: "~> 1.2",
     name: "NatSet",
     source_url: @github_url,
     description: description,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev},
     {:dialyxir, "~> 0.3", only: :dev},
     {:benchfella, "~> 0.3.0", only: :dev}]
  end

  defp description do
    "Represent sets of natural numbers compactly in Elixir using bitwise operations"
  end

  defp package do
    [maintainers: ["Hilverd Reker"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => @github_url}]
  end
end
