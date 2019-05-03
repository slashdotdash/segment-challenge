defmodule SegmentChallenge.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(SegmentChallenge.Infrastructure.DateTime.Now, []),
      supervisor(SegmentChallenge.Repo, []),
      supervisor(SegmentChallenge.Supervisor, []),
      supervisor(SegmentChallengeWeb.Endpoint, []),
      supervisor(Rihanna.Supervisor, [[postgrex: SegmentChallenge.Repo.config()]])
    ]

    opts = [strategy: :one_for_one, name: SegmentChallenge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    SegmentChallengeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
