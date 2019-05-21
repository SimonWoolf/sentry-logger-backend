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

3. Set the level threshold (defaults to :error - but see warning below):

```elixir
config :logger, SentryLoggerBackend, level: :error
```

## Fingerprints

Can supply a custom fingerprint to a Logger call with the `fingerprint` metadata, which should be a `list(String.t)` (see [Sentry's documentation](https://docs.sentry.io/data-management/rollups/?platform=javascript#custom-grouping) for more info). For example:

```elixir
Logger.warn "oh no - #{debugging data that's different each time}", fingerprint: ["oh-no"]
```

## Please note if setting level to :warn, :info, or :debug

The current version of elixir-sentry [logs problems encountered while posting to sentry at the `:warn` level](https://github.com/getsentry/sentry-elixir/blob/50ef065b6ad1c7eb5c92633f001083b0ac60c793/lib/sentry/client.ex#L163-L165).

That means that if you configure the level threshold to anything other than `:error`, and there's a problem posting to sentry, then this can result in an infinite loop of error-posting attempts.

The suggested solution for now, if you want to use a threshold other than `:error`, is to use [my fork of sentry-elixir](https://github.com/simonwoolf/sentry-elixir), which adds `:skip_sentry` metadata to that logger call. Future plans are to include a custom http client in sentry-logger-backend, see https://github.com/SimonWoolf/sentry-logger-backend/issues/1 .

## License

This project is licensed under the MIT License.
