# SentryLoggerBackend

Provides a `Logger` backend for Sentry, to automatically submit Logger events above a configurable threshold to Sentry

## Installation

1. Add `sentry_logger_backend` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:sentry_logger_backend, "~> 0.1.0"}]
end
```

2. Add SentryLoggerBackend to the list of logger backends in your config, e.g.

```elixir
config :logger, backends: [:console, SentryLoggerBackend]
```

3. Set the level threshold (defaults to :error):

```elixir
config :logger, SentryLoggerBackend, level: :error
```

## License

This project is licensed under the MIT License.
