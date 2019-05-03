defmodule SegmentChallengeWeb.DeleteStageBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Stages.Stage.Commands.DeleteStage

  def new(conn, _params) do
    %DeleteStage{
      deleted_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_deleted_by_athlete_uuid(conn)
    |> DeleteStage.new()
  end

  def assign_deleted_by_athlete_uuid(params, conn),
    do: Map.put(params, :deleted_by_athlete_uuid, current_athlete_uuid(conn))
end
