defmodule SegmentChallenge.Tasks.EndPastChallenge do
  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Commands.EndChallenge
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Router
  alias SegmentChallenge.Repo

  def execute do
    utc_now()
    |> challenges_to_end
    |> Repo.all
    |> Enum.each(&end_challenge/1)
  end

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()

  defp challenges_to_end(now) do
  	from c in ChallengeProjection,
  	where: c.status == "active" and c.end_date <= ^now
  end

  defp end_challenge(challenge) do
    Router.dispatch(%EndChallenge{
      challenge_uuid: challenge.challenge_uuid
    })
  end
end
