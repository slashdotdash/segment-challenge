defmodule SegmentChallengeWeb.FlagStageEffortBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Stages.Stage.Commands.FlagStageEffort

  def new(conn, _params) do
    %FlagStageEffort{
      flagged_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_flagged_by_athlete_uuid(conn)
    |> parse_integer("strava_activity_id")
    |> parse_integer("strava_segment_effort_id")
    |> FlagStageEffort.new()
  end

  def assign_flagged_by_athlete_uuid(params, conn),
    do: Map.put(params, :flagged_by_athlete_uuid, current_athlete_uuid(conn))

  def parse_integer(params, name) do
    Map.update(params, name, nil, fn id ->
      case Integer.parse(id) do
        {integer, _} -> integer
        _ -> nil
      end
    end)
  end
end
