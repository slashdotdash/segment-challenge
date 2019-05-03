defmodule SegmentChallenge.Tasks.ApproveStageLeaderboards do
  @moduledoc """
  Approve any stage leaderboards for stages that ended at least 3 days ago.
  """

  use Timex

  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Stages.Stage.Commands.ApproveStageLeaderboards
  alias SegmentChallenge.Projections.{ChallengeProjection, StageProjection}
  alias SegmentChallenge.Router
  alias SegmentChallenge.Repo

  def execute(now \\ utc_now())

  def execute(now) do
    now
    |> Timex.subtract(Duration.from_days(3))
    |> stages_to_approve_query()
    |> Repo.all()
    |> Enum.each(&approve_stage_leaderboards/1)
  end

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()

  defp stages_to_approve_query(ended_before) do
    from(s in StageProjection,
      where: s.status == "past" and s.approved == false and s.end_date <= ^ended_before,
      order_by: [asc: s.end_date]
    )
  end

  defp approve_stage_leaderboards(%StageProjection{} = stage) do
    %StageProjection{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = stage

    case Repo.get(ChallengeProjection, challenge_uuid) do
      %ChallengeProjection{} = challenge ->
        %ChallengeProjection{
          created_by_athlete_uuid: created_by_athlete_uuid,
          hosted_by_club_uuid: hosted_by_club_uuid
        } = challenge

        command = %ApproveStageLeaderboards{
          challenge_uuid: challenge_uuid,
          stage_uuid: stage_uuid,
          approved_by_athlete_uuid: created_by_athlete_uuid,
          approved_by_club_uuid: hosted_by_club_uuid
        }

        Router.dispatch(command)

      nil ->
        :ok
    end
  end
end
