defmodule SegmentChallengeWeb.Builders.CurrentAthleteHelper do
  def current_athlete_uuid(%{assigns: %{current_athlete: %{athlete_uuid: athlete_uuid}}}),
    do: athlete_uuid

  def current_athlete_uuid(_conn), do: nil

  def current_athlete_name(%{
        assigns: %{current_athlete: %{firstname: firstname, lastname: lastname}}
      }),
      do: "#{firstname} #{lastname}"

  def current_athlete_name(_conn), do: nil

  def assign_athlete_uuid(params, conn),
    do: Map.put(params, :athlete_uuid, current_athlete_uuid(conn))
end
