defmodule SegmentChallengeWeb.ApproveChallengeLeaderboardsBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  def new(conn, _params) do
    %SegmentChallenge.Commands.ApproveChallengeLeaderboards{
      approved_by_athlete_uuid: current_athlete_uuid(conn),
    }
  end

  def build(conn, params) do
    params
    |> assign_approved_by_athlete_uuid(conn)
    |> SegmentChallenge.Commands.ApproveChallengeLeaderboards.new
  end

  def assign_approved_by_athlete_uuid(params, conn), do: Map.put(params, :approved_by_athlete_uuid, current_athlete_uuid(conn))
end
