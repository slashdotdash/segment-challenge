defmodule SegmentChallengeWeb.JoinChallengeBuilder do
  alias SegmentChallenge.Commands.JoinChallenge

  def build(conn, params) do
    params
    |> assign_athlete(conn)
    |> JoinChallenge.new()
  end

  def assign_athlete(params, %{assigns: %{current_athlete: athlete}}) do
    params
    |> Map.put(:athlete_uuid, athlete.athlete_uuid)
    |> Map.put(:firstname, athlete.firstname)
    |> Map.put(:lastname, athlete.lastname)
    |> Map.put(:gender, athlete.gender)
  end
end
