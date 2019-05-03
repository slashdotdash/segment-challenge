defmodule SegmentChallenge.UseCases.ImportAthleteUseCase do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import SegmentChallenge.Factory

  alias SegmentChallenge.Commands.{ImportAthlete, SetAthleteClubMemberships}
  alias SegmentChallenge.Router

  def import_athlete(_context) do
    athlete_uuid = "athlete-5704447"

    :ok =
      Router.dispatch(
        struct(
          ImportAthlete,
          build(:athlete, athlete_uuid: athlete_uuid, strava_id: 5_704_447, gender: "M")
        )
      )

    [athlete_uuid: athlete_uuid]
  end

  def import_strava_athlete(_context) do
    athlete_uuid = "athlete-123456"

    athlete =
      build(:athlete,
        athlete_uuid: athlete_uuid,
        firstname: "Strava",
        lastname: "Athlete",
        strava_id: 123_456,
        gender: "M"
      )

    :ok = Router.dispatch(struct(ImportAthlete, athlete))

    [athlete_uuid: athlete_uuid]
  end

  def import_athlete_using(attrs) do
    athlete_uuid = "athlete-5704447"

    :ok =
      Router.dispatch(
        struct(
          ImportAthlete,
          build(
            :athlete,
            Keyword.merge([athlete_uuid: athlete_uuid, strava_id: 5_704_447, gender: "M"], attrs)
          )
        )
      )
  end

  def set_athlete_club_memberships(context) do
    :ok =
      Router.dispatch(%SetAthleteClubMemberships{
        athlete_uuid: context[:athlete_uuid],
        club_uuids: [context[:club_uuid]]
      })

    context
  end

  def set_athlete_empty_club_memberships(context) do
    :ok =
      Router.dispatch(%SetAthleteClubMemberships{
        athlete_uuid: context[:athlete_uuid],
        club_uuids: []
      })

    context
  end
end
