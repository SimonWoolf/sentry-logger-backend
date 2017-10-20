defmodule SentryLoggerBackend.Mixfile do
  use Mix.Project

  def project do
    [app: :sentry_logger_backend,
     version: "0.1.4",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     source_url: "https://github.com/simonwoolf/sentry-logger-backend",
     deps: deps()]
  end

  def application do
    []
  end

  defp description do
    "Provides a `Logger` backend for Sentry, to automatically submit Logger events above a configurable threshold to Sentry"
  end

  defp package do
    [
      maintainers: ["Simon Woolf, simon@simonwoolf.net"],
      licenses: ["MIT"],
      links: %{
        "github" => "https://github.com/simonwoolf/sentry-logger-backend"
      }
    ]
  end
  defp deps do
    [
      {:sentry, ">= 4.0.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
