defmodule SegmentChallengeWeb.LeaveChallengeBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Commands.LeaveChallenge

  def build(conn, params) do
    params
    |> assign_athlete_uuid(conn)
    |> LeaveChallenge.new()
  end
end
