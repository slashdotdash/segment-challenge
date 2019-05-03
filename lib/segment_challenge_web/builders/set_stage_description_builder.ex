defmodule SegmentChallengeWeb.SetStageDescriptionBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Stages.Stage.Commands.SetStageDescription

  def new(conn, _params) do
    %SetStageDescription{
      updated_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_updated_by_athlete_uuid(conn)
    |> SetStageDescription.new()
  end

  def assign_updated_by_athlete_uuid(params, conn),
    do: Map.put(params, :updated_by_athlete_uuid, current_athlete_uuid(conn))
end
