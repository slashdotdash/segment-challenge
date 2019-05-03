defmodule SegmentChallengeWeb.Builders.StravaAccessHelper do
  alias SegmentChallenge.Strava.StravaAccess

  def assign_strava_access(params, conn) do
    with {:ok, athlete_uuid} <- current_athlete_uuid(conn),
         {:ok, access_token, refresh_token} <- StravaAccess.get_access_token(athlete_uuid) do
      params
      |> Map.put(:access_token, access_token)
      |> Map.put(:refresh_token, refresh_token)
    else
      _ -> params
    end
  end

  defp current_athlete_uuid(%{assigns: %{current_athlete: %{athlete_uuid: athlete_uuid}}}),
    do: {:ok, athlete_uuid}

  defp current_athlete_uuid(_conn), do: {:error, :not_authenticated}
end
