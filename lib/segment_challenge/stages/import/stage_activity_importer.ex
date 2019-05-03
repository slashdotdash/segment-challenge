defmodule SegmentChallenge.Stages.StageActivityImporter do
  @moduledoc """
  Import an athlete's activity from Strava if applicable for any active challenges.
  """

  require Logger

  import Ecto.Query, only: [from: 2]

  alias SegmentChallenge.Athletes.Athlete
  alias SegmentChallenge.Projections.ChallengeCompetitorProjection
  alias SegmentChallenge.Projections.StageProjection
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Router
  alias SegmentChallenge.Stages.Stage.Commands.ImportStageEfforts
  alias SegmentChallenge.Stages.Stage.Commands.ImportStageEfforts.StageEffort
  alias SegmentChallenge.Stages.StageEffortMapper
  alias SegmentChallenge.Strava.StravaAccess
  alias SegmentChallenge.Strava.Gateway, as: StravaGateway

  def execute(args) do
    strava_activity_id = Keyword.fetch!(args, :strava_activity_id)
    strava_athlete_id = Keyword.fetch!(args, :strava_athlete_id)

    athlete_uuid = Athlete.identity(strava_athlete_id)

    with {:ok, client} <- strava_client(athlete_uuid),
         {:ok, %Strava.DetailedActivity{} = activity} <-
           strava_activity(client, strava_activity_id) do
      %Strava.DetailedActivity{start_date_local: start_date_local} = activity

      stages_query =
        athlete_active_stages_query(athlete_uuid, DateTime.to_naive(start_date_local))

      for %StageProjection{stage_uuid: stage_uuid} = stage <- Repo.all(stages_query) do
        stage_efforts =
          stage
          |> StageEffortMapper.map_to_stage_efforts(activity)
          |> List.wrap()
          |> Enum.sort_by(&stage_effort_start_date/1)

        :ok = import_stage_efforts(stage_uuid, stage_efforts)
      end

      :ok
    else
      {:error, {:no_strava_access, athlete_uuid}} ->
        Logger.warn(fn -> "No Strava access for athlete #{inspect(athlete_uuid)}" end)

        :ok

      {:error, :activity_not_found} ->
        Logger.warn(fn -> "Strava activity not found #{inspect(strava_activity_id)}" end)

        :ok

      reply ->
        reply
    end
  end

  defp import_stage_efforts(_stage_uuid, []), do: :ok

  defp import_stage_efforts(stage_uuid, stage_efforts) do
    command = %ImportStageEfforts{stage_uuid: stage_uuid, stage_efforts: stage_efforts}

    case Router.dispatch(command) do
      {:error, {:validation_failure, errors}} ->
        Logger.warn(fn -> "Import stage efforts failed due to: " <> inspect(errors) end)
        :ok

      reply ->
        reply
    end
  end

  defp stage_effort_start_date(%StageEffort{start_date: start_date}), do: start_date

  defp strava_client(athlete_uuid) do
    case StravaAccess.get_access_token(athlete_uuid) do
      {:ok, access_token, refresh_token} ->
        client = StravaGateway.build_client(athlete_uuid, access_token, refresh_token)

        {:ok, client}

      {:error, :not_found} ->
        {:error, {:no_strava_access, athlete_uuid}}
    end
  end

  defp strava_activity(client, strava_activity_id) do
    StravaGateway.get_activity(client, strava_activity_id, include_all_efforts: true)
  end

  defp athlete_active_stages_query(athlete_uuid, start_date_local) do
    from(
      s in StageProjection,
      join: cc in ChallengeCompetitorProjection,
      on: cc.challenge_uuid == s.challenge_uuid,
      where:
        cc.athlete_uuid == ^athlete_uuid and s.start_date_local <= ^start_date_local and
          s.end_date_local >= ^start_date_local and
          (s.status == "active" or (s.status == "past" and s.approved == false))
    )
  end
end
