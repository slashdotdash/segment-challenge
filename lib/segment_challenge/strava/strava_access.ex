defmodule SegmentChallenge.Strava.StravaAccess do
  use Ecto.Schema

  import Ecto.Query

  alias SegmentChallenge.Strava.StravaAccess
  alias SegmentChallenge.Repo

  @primary_key {:athlete_uuid, :string, []}

  schema "strava_access" do
    field(:access_token, :string)
    field(:refresh_token, :string)

    timestamps()
  end

  def get_access_token(athlete_uuid) do
    query = from(sa in StravaAccess, where: sa.athlete_uuid == ^athlete_uuid)

    case Repo.one(query) do
      %StravaAccess{access_token: access_token, refresh_token: refresh_token} ->
        {:ok, access_token, refresh_token}

      nil ->
        {:error, :not_found}
    end
  end

  def assign_access_token(athlete_uuid, access_token, refresh_token) do
    strava_access = %StravaAccess{
      athlete_uuid: athlete_uuid,
      access_token: access_token,
      refresh_token: refresh_token
    }

    Repo.insert(
      strava_access,
      on_conflict: [set: [access_token: access_token, refresh_token: refresh_token]],
      conflict_target: [:athlete_uuid]
    )
    |> case do
      {:ok, _strava_access} -> :ok
      reply -> reply
    end
  end
end
