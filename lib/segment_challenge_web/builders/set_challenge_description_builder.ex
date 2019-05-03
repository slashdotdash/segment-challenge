defmodule SegmentChallengeWeb.SetChallengeDescriptionBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Commands.SetChallengeDescription

  def new(conn, _params) do
    %SetChallengeDescription{
      updated_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_updated_by_athlete_uuid(conn)
    |> SetChallengeDescription.new()
  end

  def assign_updated_by_athlete_uuid(params, conn),
    do: Map.put(params, :updated_by_athlete_uuid, current_athlete_uuid(conn))
end
