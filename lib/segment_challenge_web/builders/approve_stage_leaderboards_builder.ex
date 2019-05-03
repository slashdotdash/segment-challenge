defmodule SegmentChallengeWeb.ApproveStageLeaderboardsBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Stages.Stage.Commands.ApproveStageLeaderboards

  def new(conn, _params) do
    %ApproveStageLeaderboards{
      approved_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_approved_by_athlete_uuid(conn)
    |> ApproveStageLeaderboards.new()
  end

  def assign_approved_by_athlete_uuid(params, conn),
    do: Map.put(params, :approved_by_athlete_uuid, current_athlete_uuid(conn))
end
