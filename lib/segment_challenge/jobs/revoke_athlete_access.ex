defmodule SegmentChallenge.Jobs.RevokeAthleteAccess do
  @moduledoc """
  Revoke an athlete's Strava access.
  """

  @behaviour Rihanna.Job

  require Logger

  import Ecto.Query

  alias SegmentChallenge.Athletes.Athlete
  alias SegmentChallenge.Strava.StravaAccess
  alias SegmentChallenge.Repo

  def perform(args) do
    strava_athlete_id = Keyword.fetch!(args, :strava_athlete_id)

    athlete_uuid = Athlete.identity(strava_athlete_id)
    query = from(s in StravaAccess, where: s.athlete_uuid == ^athlete_uuid)

    case Repo.delete_all(query) do
      {1, nil} -> :ok
      {0, _} -> {:error, {:failed_to_revoke_strava_access, strava_athlete_id}}
    end
  end

  def after_error(error, args) do
    Rollbax.report_message(:error, "Revoke Strava access for athlete failed", %{
      "error" => inspect(error),
      "args" => inspect(args)
    })
  end
end
