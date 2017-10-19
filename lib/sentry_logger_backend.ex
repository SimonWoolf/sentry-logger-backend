defmodule SentryLoggerBackend do
  @moduledoc """
    Provides a `Logger` backend for Sentry. This will automatically
    submit Error level Logger events to Sentry.

    ### Configuration
    Simply add the following to your config:

        config :logger, backends: [:console, SentryLoggerBackend]

    To set the level threshold:

        config :logger, SentryLoggerBackend, level: :error
  """

  use GenEvent
  defstruct level: :error

  def init(__MODULE__) do
    {:ok, configure([])}
  end

  def handle_call({:configure, opts}, state) do
    {:ok, :ok, configure(opts, state)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    # Ignore non-local
    {:ok, state}
  end

  def handle_event({level, _, {Logger, msg, _timestamp, metadata}}, state = %{level: min_level}) do
    if meet_level?(level, min_level) && !metadata[:skip_sentry] do
      opts = case Keyword.pop(metadata, :fingerprint) do
        {nil, remaining} -> [
            level: normalise_level(level),
            extra: process_metadata(remaining)
          ]
        {fingerprint, remaining} -> [
            level: normalise_level(level),
            fingerprint: Enum.map(fingerprint, &to_string/1),
            extra: process_metadata(remaining)
          ]
      end
      Sentry.capture_message(to_string(msg), opts)
    end

    {:ok, state}
  end

  def handle_event(_data, state) do
    {:ok, state}
  end

  defp configure(opts, state \\ %__MODULE__{}) do
    config =
      Application.get_env(:logger, __MODULE__, [])
      |> Keyword.merge(opts)
    Application.put_env(:logger, __MODULE__, config)

    %__MODULE__{state | level: config[:level]}
  end

  defp process_metadata(metadata) do
    metadata
    |> Enum.map(&stringify_values/1)
    |> Enum.into(Map.new)
  end

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  # Avoid quote marks around string vals, but otherwise inspect
  defp stringify_values({k, v}) when is_binary(v), do: {k, v}
  defp stringify_values({k, v}), do: {k, inspect(v)}

  # Sentry doesn't understand :warn
  defp normalise_level(:warn), do: :warning
  defp normalise_level(other), do: other
end
