defmodule SegmentChallenge.Projections.AthleteCompetitorProjection do
  @doc """
  Track athlete's competing in challenges
  """

  use Ecto.Schema

  alias SegmentChallenge.Projections.AthleteCompetitorProjection

  @primary_key {:athlete_uuid, :string, []}

  schema "athlete_competitors" do
    field(:firstname, :string)
    field(:lastname, :string)
    field(:email, :string)
    field(:profile, :string)

    timestamps()
  end

  defmodule Builder do
    use Commanded.Projections.Ecto, name: "AthleteCompetitorProjection"

    alias SegmentChallenge.Events.{
      AthleteEmailChanged,
      AthleteImported,
      AthleteRenamed,
      AthleteProfileChanged
    }

    project %AthleteImported{} = event, fn multi ->
      %AthleteImported{
        athlete_uuid: athlete_uuid,
        firstname: firstname,
        lastname: lastname,
        email: email,
        profile: profile
      } = event

      Ecto.Multi.insert(multi, :athlete_competitor, %AthleteCompetitorProjection{
        athlete_uuid: athlete_uuid,
        firstname: firstname,
        lastname: lastname,
        email: email,
        profile: profile
      })
    end

    project %AthleteEmailChanged{} = event, fn multi ->
      %AthleteEmailChanged{athlete_uuid: athlete_uuid, email: email} = event

      Ecto.Multi.update_all(multi, :athlete_competitor, athlete_competitor_query(athlete_uuid),
        set: [
          email: email
        ]
      )
    end

    project %AthleteRenamed{} = event, fn multi ->
      %AthleteRenamed{athlete_uuid: athlete_uuid, firstname: firstname, lastname: lastname} =
        event

      Ecto.Multi.update_all(multi, :athlete_competitor, athlete_competitor_query(athlete_uuid),
        set: [
          firstname: firstname,
          lastname: lastname
        ]
      )
    end

    project %AthleteProfileChanged{} = event, fn multi ->
      %AthleteProfileChanged{athlete_uuid: athlete_uuid, profile: profile} = event

      Ecto.Multi.update_all(multi, :athlete_competitor, athlete_competitor_query(athlete_uuid),
        set: [
          profile: profile
        ]
      )
    end

    defp athlete_competitor_query(athlete_uuid) do
      from(ac in AthleteCompetitorProjection,
        where: ac.athlete_uuid == ^athlete_uuid
      )
    end
  end
end
