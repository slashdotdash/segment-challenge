defmodule SegmentChallengeWeb.HostChallengeBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  def new(conn, _params) do
    %SegmentChallenge.Commands.HostChallenge{
      hosted_by_athlete_uuid: current_athlete_uuid(conn),
    }
  end

  def build(conn, params) do
    params
    |> assign_hosted_by_athlete_uuid(conn)
    |> SegmentChallenge.Commands.HostChallenge.new
  end

  def assign_hosted_by_athlete_uuid(params, conn), do: Map.put(params, :hosted_by_athlete_uuid, current_athlete_uuid(conn))
end
