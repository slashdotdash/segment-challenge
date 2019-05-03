defmodule SegmentChallenge.Tasks.StartActiveChallenge do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Commands.StartChallenge
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Router
  alias SegmentChallenge.Repo

  def execute, do: execute(utc_now())

  def execute(now) do
    now
    |> challenges_to_start()
    |> Repo.all()
    |> Enum.each(&start_challenge/1)
  end

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()

  defp challenges_to_start(now) do
  	from c in ChallengeProjection,
  	where: c.status == "upcoming" and c.start_date <= ^now
  end

  defp start_challenge(challenge) do
    Router.dispatch(%StartChallenge{
      challenge_uuid: challenge.challenge_uuid
    })
  end
end
