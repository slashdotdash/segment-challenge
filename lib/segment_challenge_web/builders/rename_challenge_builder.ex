defmodule SegmentChallengeWeb.RenameChallengeBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  def new(conn, _params) do
    %SegmentChallenge.Commands.RenameChallenge{
      renamed_by_athlete_uuid: current_athlete_uuid(conn),
    }
  end

  def build(conn, params) do
    params
    |> assign_renamed_by_athlete_uuid(conn)
    |> SegmentChallenge.Commands.RenameChallenge.new
  end

  def assign_renamed_by_athlete_uuid(params, conn), do: Map.put(params, :renamed_by_athlete_uuid, current_athlete_uuid(conn))
end
