defmodule SegmentChallengeWeb.CancelChallengeBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Commands.CancelChallenge

  def new(conn, _params) do
    %CancelChallenge{
      cancelled_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_cancelled_by_athlete_uuid(conn)
    |> CancelChallenge.new()
  end

  def assign_cancelled_by_athlete_uuid(params, conn),
    do: Map.put(params, :cancelled_by_athlete_uuid, current_athlete_uuid(conn))
end
