use Mix.Config

config :commanded, event_store_adapter: Commanded.EventStore.Adapters.EventStore

config :commanded_ecto_projections, repo: SegmentChallenge.Repo

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :oauth2, serializers: %{"application/json" => Jason}

config :phoenix, :json_library, Jason
config :phoenix, :format_encoders, json: Jason

config :rihanna,
  dispatcher_max_concurrency: 25,
  dispatcher_poll_interval: :timer.seconds(15),
  producer_postgres_connection: {Ecto, SegmentChallenge.Repo}

config :scrivener_html,
  routes_helper: SegmentChallengeWeb.Router.Helpers,
  view_style: :bulma

config :segment_challenge, ecto_repos: [SegmentChallenge.Repo]

# Configures the endpoint
config :segment_challenge, SegmentChallengeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "UD4Ugain7VEBvwgrrQ64nJQt0Vzg0RjnRfgm8ADxP47MVl37ifc4e5vi7CJ+fqTS",
  render_errors: [view: SegmentChallengeWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SegmentChallenge.PubSub, adapter: Phoenix.PubSub.PG2]

config :strava, timeout: 15_000, recv_timeout: 60_000

config :vex,
  sources: [
    [activity_type: SegmentChallenge.Commands.Validation.ActivityTypeValidator],
    [activity_types: SegmentChallenge.Commands.Validation.ActivityTypesValidator],
    [challenge_type: SegmentChallenge.Commands.Validation.ChallengeTypeValidator],
    [competitors: SegmentChallenge.Commands.Validation.CompetitorsValidator],
    [component: SegmentChallenge.Commands.Validation.ComponentValidator],
    [component_list: SegmentChallenge.Commands.Validation.ComponentListValidator],
    [email: SegmentChallenge.Commands.Validation.EmailValidator],
    [futuredate: SegmentChallenge.Commands.Validation.FutureDateValidator],
    [gender: SegmentChallenge.Commands.Validation.GenderValidator],
    [goal_recurrence: SegmentChallenge.Commands.Validation.GoalRecurrenceValidator],
    [naivedatetime: SegmentChallenge.Commands.Validation.NaiveDateTimeValidator],
    [pointsadjustment: SegmentChallenge.Commands.Validation.PointsAdjustmentValidator],
    [stage_efforts: SegmentChallenge.Commands.Validation.StageEffortsValidator],
    [stage_type: SegmentChallenge.Commands.Validation.StageTypeValidator],
    [string: SegmentChallenge.Commands.Validation.SringValidator],
    [units: SegmentChallenge.Commands.Validation.UnitsValidator],
    [uuid: SegmentChallenge.Commands.Validation.UuidValidator],
    Vex.Validators
  ]

# Import environment specific config.
import_config "#{Mix.env()}.exs"

if File.exists?("config/#{Mix.env()}.secret.exs") do
  import_config "#{Mix.env()}.secret.exs"
end
