defmodule SegmentChallenge.Tasks.ApproveChallengeLeaderboards do
  @moduledoc """
  Approve any challenge leaderboards for challenges that ended at least 3 days
  ago and have all stage leaderboards approved.
  """

  import Ecto.Query, only: [from: 2]

  use Timex

  alias SegmentChallenge.Commands.ApproveChallengeLeaderboards
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Router
  alias SegmentChallenge.Repo

  def execute(now \\ utc_now())

  def execute(now) do
    now
    |> Timex.subtract(Duration.from_days(3))
    |> challenges_to_approve_query()
    |> Repo.all()
    |> Enum.filter(&all_stages_approved?/1)
    |> Enum.each(&approve_challenge_leaderboards/1)
  end

  defp challenges_to_approve_query(ended_before) do
    from(c in ChallengeProjection,
      where: c.status == "past" and c.approved == false and c.end_date <= ^ended_before,
      order_by: [asc: c.end_date]
    )
  end

  # Ensure all stages in the challenge have been approved.
  defp all_stages_approved?(%ChallengeProjection{challenge_uuid: challenge_uuid}) do
    challenge_uuid
    |> StagesInChallengeQuery.new()
    |> Repo.all()
    |> Enum.all?(& &1.approved)
  end

  defp approve_challenge_leaderboards(%ChallengeProjection{} = challenge) do
    %ChallengeProjection{
      challenge_uuid: challenge_uuid,
      created_by_athlete_uuid: created_by_athlete_uuid,
      hosted_by_club_uuid: hosted_by_club_uuid
    } = challenge

    command = %ApproveChallengeLeaderboards{
      challenge_uuid: challenge_uuid,
      approved_by_athlete_uuid: created_by_athlete_uuid,
      approved_by_club_uuid: hosted_by_club_uuid
    }

    :ok = Router.dispatch(command)
  end

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()
end
