defmodule SegmentChallenge.Mixfile do
  use Mix.Project

  def project do
    [
      app: :segment_challenge,
      version: "1.0.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {SegmentChallenge.Application, []},
      env: [environment_name: Mix.env()],
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support", "test/use_cases", "test/segment_challenge_web/pages"]
  end

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:bamboo, "~> 1.1"},
      {:canada, "~> 1.0"},
      {:cmark, "~> 0.7"},
      {:commanded, "~> 0.18"},
      {:commanded_eventstore_adapter, "~> 0.5"},
      {:commanded_ecto_projections, "~> 0.8"},
      {:decimal, "~> 1.6"},
      {:ecto_sql, "~> 3.0"},
      {:elixir_uuid, "~> 1.1"},
      {:eventstore, "~> 0.16"},
      {:ex_rated, "~> 1.3"},
      {:exconstructor, "~> 1.0"},
      {:exnumerator, "~> 1.7"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.1"},
      {:number, "~> 1.0"},
      {:phoenix, "~> 1.4", override: true},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.13"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_pubsub, "~> 1.0"},
      {:pid_file, "~> 0.1"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:postgrex, "~> 0.14"},
      {:remote_ip, "~> 0.1"},
      {:rihanna, "~> 1.2"},
      {:rollbax, "~> 0.10"},
      {:scrivener_ecto, "~> 2.0"},
      {:scrivener_html, "~> 1.7"},
      {:sched_ex, "~> 1.0"},
      {:slugger, github: "sutherland/slugger", ref: "86cd0388c84f23921f341a051737384169b7c659"},
      {:strava, "~> 1.0"},
      {:timex, "~> 3.1"},
      {:vex, "~> 0.6"},

      # Development tools
      {:ex_machina, "~> 2.2", only: :test},
      {:exvcr, "~> 0.9", only: :test}
    ]
  end

  defp aliases do
    [
      "event_store.setup": [
        "event_store.create",
        "event_store.init"
      ],
      "read_store.setup": [
        "ecto.create",
        "ecto.migrate"
      ],
      setup: [
        "event_store.setup",
        "read_store.setup"
      ],
      reset: [
        "event_store.drop",
        "event_store.setup",
        "ecto.drop",
        "read_store.setup"
      ]
    ]
  end
end
