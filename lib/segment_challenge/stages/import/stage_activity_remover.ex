defmodule SegmentChallenge.Stages.StageActivityRemover do
  @moduledoc """
  Remove an athlete's activity and any related stage efforts.
  """

  require Logger

  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Athletes.Athlete
  alias SegmentChallenge.Projections.ChallengeCompetitorProjection
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Router
  alias SegmentChallenge.Stages.Stage.Commands.RemoveStageActivity

  def execute(args) do
    strava_activity_id = Keyword.fetch!(args, :strava_activity_id)
    strava_athlete_id = Keyword.fetch!(args, :strava_athlete_id)

    now = Keyword.get(args, :now, NaiveDateTime.utc_now())

    athlete_uuid = Athlete.identity(strava_athlete_id)
    stages_uuids_query = athlete_active_stages_query(athlete_uuid, now)

    for stage_uuid <- Repo.all(stages_uuids_query) do
      remove_stage_effort(stage_uuid, strava_activity_id)
    end

    :ok
  end

  defp remove_stage_effort(stage_uuid, strava_activity_id) do
    command = %RemoveStageActivity{stage_uuid: stage_uuid, strava_activity_id: strava_activity_id}

    Router.dispatch(command)
  end

  defp athlete_active_stages_query(athlete_uuid, now) do
    from(
      s in StageProjection,
      join: cc in ChallengeCompetitorProjection,
      on: cc.challenge_uuid == s.challenge_uuid,
      where:
        cc.athlete_uuid == ^athlete_uuid and s.start_date_local <= ^now and
          s.end_date_local >= ^now and
          (s.status == "active" or (s.status == "past" and s.approved == false)),
      select: s.stage_uuid
    )
  end
end
