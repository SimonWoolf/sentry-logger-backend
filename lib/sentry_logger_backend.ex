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

  def handle_event({level, _, {Logger, msg, timestamp, metadata}}, state = %{level: min_level}) do
    if meet_level?(level, min_level) && !metadata[:skip_sentry] do
      Sentry.capture_message(msg, [
        level: level,
        extra: Enum.into(metadata, Map.new)
      ])
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

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end
end
