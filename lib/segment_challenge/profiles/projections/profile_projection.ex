defmodule SegmentChallenge.Projections.Profiles.ProfileProjection do
  @moduledoc """
  Record the profile image URL for athletes and clubs as they are imported
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:source_uuid, :string, []}

  schema "profiles" do
    field(:source, :string)
    field(:profile, :string)

    timestamps()
  end

  def changeset(profile, params \\ %{}) do
    profile
    |> cast(params, [:source, :profile])
  end

  alias SegmentChallenge.Projections.Profiles.ProfileProjection

  defmodule Builder do
    use Commanded.Projections.Ecto, name: "ProfileProjection"

    alias SegmentChallenge.Events.{
      AthleteImported,
      AthleteProfileChanged,
      ClubImported,
      ClubProfileChanged
    }

    project %AthleteImported{athlete_uuid: athlete_uuid, profile: profile}, fn multi ->
      upsert_profile(multi, "athlete", athlete_uuid, profile)
    end

    project %AthleteProfileChanged{athlete_uuid: athlete_uuid, profile: profile}, fn multi ->
      upsert_profile(multi, "athlete", athlete_uuid, profile)
    end

    project %ClubImported{club_uuid: club_uuid, profile: profile}, fn multi ->
      upsert_profile(multi, "club", club_uuid, profile)
    end

    project %ClubProfileChanged{club_uuid: club_uuid, profile: profile}, fn multi ->
      upsert_profile(multi, "club", club_uuid, profile)
    end

    defp upsert_profile(multi, source, source_uuid, profile_url) do
      profile = %ProfileProjection{
        source: source,
        source_uuid: source_uuid,
        profile: profile_url
      }

      Ecto.Multi.insert(
        multi,
        UUID.uuid4(),
        profile,
        on_conflict: [set: [profile: profile_url]],
        conflict_target: [:source, :source_uuid]
      )
    end
  end
end
