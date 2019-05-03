defmodule SegmentChallengeWeb.CreateStageBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper
  import SegmentChallengeWeb.Builders.DateTimeHelper
  import SegmentChallengeWeb.Builders.StravaAccessHelper
  import SegmentChallengeWeb.Builders.UUIDHelper

  alias SegmentChallenge.Challenges.ChallengeStageService

  alias SegmentChallenge.Stages.Stage.Commands.{
    CreateSegmentStage,
    CreateActivityStage
  }

  def new(%{assigns: %{challenge: challenge}}, _params) do
    next_stage = ChallengeStageService.next_stage(challenge)

    %CreateSegmentStage{
      challenge_uuid: challenge.challenge_uuid,
      stage_number: next_stage.stage_number,
      start_date: next_stage.start_date,
      start_date_local: next_stage.start_date_local,
      end_date: next_stage.end_date,
      end_date_local: challenge.end_date_local
    }
  end

  def build(conn, %{"type" => "segment"} = params) do
    params
    |> assign_uuid(:stage_uuid)
    |> assign_created_by_athlete_uuid(conn)
    |> assign_strava_access(conn)
    |> parse_date_time("start_date")
    |> parse_date_time("start_date_local")
    |> parse_date_time("end_date")
    |> parse_date_time("end_date_local")
    |> CreateSegmentStage.new()
  end

  def build(conn, %{"type" => "activity"} = params) do
    params
    |> assign_uuid(:stage_uuid)
    |> assign_created_by_athlete_uuid(conn)
    |> parse_date_time("start_date")
    |> parse_date_time("start_date_local")
    |> parse_date_time("end_date")
    |> parse_date_time("end_date_local")
    |> parse_float("goal")
    |> CreateActivityStage.new()
  end

  def assign_created_by_athlete_uuid(params, conn),
    do: Map.put(params, :created_by_athlete_uuid, current_athlete_uuid(conn))

  def parse_float(params, key) do
    Map.update(params, key, nil, fn value ->
      case Float.parse(value) do
        {float, ""} -> float
        _ -> value
      end
    end)
  end
end
