defmodule SegmentChallenge.Stages.StageEffortImporter do
  use Timex

  import Ecto.Query, only: [from: 2]

  require Logger

  alias SegmentChallenge.Stages.Stage.Commands.ImportStageEfforts
  alias SegmentChallenge.Stages.Stage.Commands.ImportStageEfforts.StageEffort
  alias SegmentChallenge.Projections.{ChallengeCompetitorProjection, StageProjection}
  alias SegmentChallenge.{Repo, Router}
  alias SegmentChallenge.Strava.Gateway, as: StravaGateway
  alias SegmentChallenge.Strava.StravaAccess
  alias SegmentChallenge.Stages.StageEffortMapper

  def execute(stage, opts \\ [])

  def execute(stage_uuid, opts) when is_binary(stage_uuid) do
    case Repo.get(StageProjection, stage_uuid) do
      %StageProjection{} = stage -> execute(stage, opts)
      nil -> {:error, :stage_not_found}
    end
  end

  def execute(%StageProjection{} = stage, opts) do
    %StageProjection{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = stage

    for {athlete_uuid, access_token, refresh_token} <- challenge_competitors(challenge_uuid) do
      client = StravaGateway.build_client(athlete_uuid, access_token, refresh_token)

      with {:ok, stage_efforts} <- get_stage_efforts(client, stage, opts),
           :ok <- import_stage_efforts(stage_uuid, stage_efforts) do
        :ok
      else
        {:error, error} ->
          Logger.error(fn ->
            "Failed to import efforts for stage " <>
              inspect(stage_uuid) <>
              " for athlete " <> inspect(athlete_uuid) <> " due to error: " <> inspect(error)
          end)
      end
    end

    record_import(stage_uuid)

    :ok
  end

  # Get competitors in challenge who have a Strava access token
  defp challenge_competitors(challenge_uuid) do
    query =
      from(
        c in ChallengeCompetitorProjection,
        join: s in StravaAccess,
        on: s.athlete_uuid == c.athlete_uuid,
        where: c.challenge_uuid == ^challenge_uuid,
        select: {s.athlete_uuid, s.access_token, s.refresh_token}
      )

    Repo.all(query)
  end

  defp get_stage_efforts(client, %StageProjection{} = stage, opts) do
    case get_stage_activities(client, stage, opts) do
      {:ok, activities} ->
        stage_efforts =
          activities
          |> Enum.map(&StageEffortMapper.map_to_stage_efforts(stage, &1))
          |> Enum.flat_map(&List.wrap/1)
          |> Enum.sort_by(&stage_effort_start_date/1)

        {:ok, stage_efforts}

      reply ->
        reply
    end
  end

  defp get_stage_activities(client, %StageProjection{stage_type: stage_type} = stage, opts)
       when stage_type in ["mountain", "flat", "rolling"] do
    %StageProjection{
      strava_segment_id: segment_id,
      start_date_local: start_date_local,
      end_date_local: end_date_local
    } = stage

    start_date_local = Keyword.get(opts, :start_date_local, start_date_local)
    end_date_local = Keyword.get(opts, :end_date_local, end_date_local)

    Logger.info(fn ->
      "Importing stage efforts for Strava segment #{inspect(segment_id)} " <>
        "between #{inspect(start_date_local)} and #{inspect(end_date_local)}"
    end)

    try do
      activities =
        client
        |> StravaGateway.segment_efforts(segment_id, start_date_local, end_date_local)
        |> Enum.map(fn
          %Strava.DetailedSegmentEffort{activity: %Strava.MetaActivity{id: activity_id}} ->
            activity_id
        end)
        |> Enum.uniq()
        |> Enum.map(fn activity_id ->
          case StravaGateway.get_activity(client, activity_id, include_all_efforts: true) do
            {:ok, activity} -> activity
            {:error, error} -> throw(error)
          end
        end)

      {:ok, activities}
    rescue
      error -> {:error, error}
    catch
      error -> {:error, error}
    end
  end

  defp get_stage_activities(client, %StageProjection{stage_type: "race"} = stage, opts) do
    %StageProjection{start_date: start_date, end_date: end_date} = stage

    start_date = Keyword.get(opts, :start_date, start_date)
    end_date = Keyword.get(opts, :end_date, end_date)

    Logger.info(fn ->
      "Importing Strava activities between #{inspect(start_date)} and #{inspect(end_date)}"
    end)

    try do
      activities =
        client
        |> StravaGateway.athlete_activities(start_date, end_date)
        |> Enum.map(fn %Strava.SummaryActivity{} = activity ->
          %Strava.SummaryActivity{id: activity_id} = activity

          case StravaGateway.get_activity(client, activity_id, include_all_efforts: true) do
            {:ok, activity} -> activity
            {:error, error} -> throw(error)
          end
        end)

      {:ok, activities}
    rescue
      error -> {:error, error}
    catch
      error -> {:error, error}
    end
  end

  defp get_stage_activities(client, %StageProjection{} = stage, opts) do
    %StageProjection{start_date: start_date, end_date: end_date} = stage

    start_date = Keyword.get(opts, :start_date, start_date)
    end_date = Keyword.get(opts, :end_date, end_date)

    Logger.info(fn ->
      "Importing Strava activities between #{inspect(start_date)} and #{inspect(end_date)}"
    end)

    try do
      activities =
        client
        |> StravaGateway.athlete_activities(start_date, end_date)
        |> Enum.to_list()

      {:ok, activities}
    rescue
      error ->
        {:error, error}
    end
  end

  defp stage_effort_start_date(%StageEffort{start_date: start_date}), do: start_date

  defp import_stage_efforts(_stage_uuid, []), do: :ok

  defp import_stage_efforts(stage_uuid, stage_efforts) do
    command = %ImportStageEfforts{stage_uuid: stage_uuid, stage_efforts: stage_efforts}

    Router.dispatch(command)
  end

  defp record_import(stage_uuid) do
    Repo.update_all(
      stage_query(stage_uuid),
      set: [
        refreshed_at: utc_now()
      ]
    )
  end

  defp stage_query(stage_uuid) do
    from(s in StageProjection, where: s.stage_uuid == ^stage_uuid)
  end

  def utc_now, do: DateTime.utc_now()
end
