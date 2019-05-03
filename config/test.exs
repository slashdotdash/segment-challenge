use Mix.Config

config :logger, level: :warn
config :logger, backends: []

config :commanded, :assert_receive_event_timeout, 2_000

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  database: "segmentchallenge_eventstore_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 1

config :ex_unit, capture_log: true, assert_receive_timeout: 2_000

config :exvcr,
  filter_sensitive_data: [
    [pattern: "Bearer [0-9a-z]+", placeholder: "<<access_key>>"]
  ],
  filter_url_params: false,
  response_headers_blacklist: ["Set-Cookie", "X-Request-Id"]

config :rollbax, enabled: false

config :segment_challenge,
  email_provider: SegmentChallenge.Test.Email,
  strava_rate_limit_requests: 1_000

config :segment_challenge, SegmentChallenge.Email.Mailer, adapter: Bamboo.TestAdapter

config :segment_challenge, SegmentChallengeWeb.Endpoint,
  http: [port: 4001],
  server: false

# Configure your database
config :segment_challenge, SegmentChallenge.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "segmentchallenge_readstore_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
