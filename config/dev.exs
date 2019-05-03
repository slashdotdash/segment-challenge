use Mix.Config

config :logger, :console, level: :info, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :rihanna,
  dispatcher_max_concurrency: 1,
  dispatcher_poll_interval: :timer.minutes(1)

config :rollbax, enabled: false

config :segment_challenge, SegmentChallenge.Email.Mailer, adapter: Bamboo.LocalAdapter

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :segment_challenge, SegmentChallengeWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Watch static and templates for browser reloading.
config :segment_challenge, SegmentChallengeWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/segment_challenge_web/views/.*(ex)$},
      ~r{lib/segment_challenge_web/templates/.*(eex)$}
    ]
  ]

# Configure your database
config :segment_challenge, SegmentChallenge.Repo,
  database: "segmentchallenge_readstore_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 5

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  database: "segmentchallenge_eventstore_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 5,
  pool_overflow: 0
