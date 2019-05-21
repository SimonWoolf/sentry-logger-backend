defmodule SentryLoggerBackend do
  @moduledoc """
    Provides a `Logger` backend for Sentry. This will automatically
    submit Error level Logger events to Sentry.

    ### Configuration
    Simply add the following to your config:

        config :logger, backends: [:console, SentryLoggerBackend]

    To set the level threshold:

        config :logger, SentryLoggerBackend, level: :error

    To set a fingerprint function:

        # The `process` function here takes 2 arguments:
        # 1. any metadata received from logger for `fingerprint`
        # 2. the message string from the logger
        # It should return a list of elements that work with `to_string`
        config :logger, SentryLoggerBackend, fingerprint: &MyApp.Fingerprinting.process/2
  """

  use GenEvent
  defstruct level: :error, fingerprint_callback: nil

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

  def handle_event(
        {level, _, {Logger, msg, _timestamp, metadata}},
        state = %{level: min_level, fingerprint_callback: fingerprint_callback}
      ) do
    if meet_level?(level, min_level) && !metadata[:skip_sentry] do
      msg = to_string(msg)
      {fingerprint_meta, remaining} = Keyword.pop(metadata, :fingerprint)
      fingerprint = fingerprint_callback.(fingerprint_meta, msg)

      opts =
        case {is_otp_crash(msg), {fingerprint, remaining}} do
          {false, {nil, remaining}} ->
            [level: normalise_level(level), extra: process_metadata(remaining)]

          {true, {nil, remaining}} ->
            [
              level: normalise_level(level),
              fingerprint: extract_fingerprint_from_otp_crash(msg),
              extra: process_metadata(remaining)
            ]

          {_, {fingerprint, remaining}} ->
            [
              level: normalise_level(level),
              fingerprint: Enum.map(fingerprint, &to_string/1),
              extra: process_metadata(remaining)
            ]
        end

      Sentry.capture_message(msg, opts)
    end

    {:ok, state}
  end

  def handle_event(_data, state) do
    {:ok, state}
  end

  defp default_fingerprint(nil, _msg), do: nil
  defp default_fingerprint(fingerprint_meta, _msg), do: fingerprint_meta

  defp configure(opts, state \\ %__MODULE__{}) do
    config =
      Application.get_env(:logger, __MODULE__, [])
      |> Keyword.merge(opts)

    Application.put_env(:logger, __MODULE__, config)

    %__MODULE__{
      state
      | level: config[:level] || :error,
        fingerprint: config[:fingerprint] || (&default_fingerprint/2)
    }
  end

  defp process_metadata(metadata) do
    metadata
    |> Enum.map(&stringify_values/1)
    |> Enum.into(Map.new())
  end

  defp meet_level?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp is_otp_crash(msg) do
    String.starts_with?(msg, "Error in process")
  end

  defp extract_fingerprint_from_otp_crash(msg) do
    Regex.run(~r/file: [^\]]*/, msg)
  end

  # Avoid quote marks around string vals, but otherwise inspect
  defp stringify_values({k, v}) when is_binary(v), do: {k, v}
  defp stringify_values({k, v}), do: {k, inspect(v)}

  # Sentry doesn't understand :warn
  defp normalise_level(:warn), do: :warning
  defp normalise_level(other), do: other
end
