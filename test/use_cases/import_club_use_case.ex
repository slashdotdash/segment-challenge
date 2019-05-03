defmodule SegmentChallenge.UseCases.ImportClubUseCase do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import SegmentChallenge.Factory

  alias SegmentChallenge.Commands.{JoinClub, LeaveClub}
  alias SegmentChallenge.Router

  def import_club(_context) do
    strava_club_id = 7289
    club_uuid = UUID.uuid4()

    :ok = Router.dispatch(build(:import_club, club_uuid: club_uuid, strava_id: strava_club_id))

    [strava_club_id: strava_club_id, club_uuid: club_uuid]
  end

  def import_private_club(_context) do
    strava_club_id = 7289
    club_uuid = UUID.uuid4()

    :ok =
      Router.dispatch(
        build(:import_club, club_uuid: club_uuid, strava_id: strava_club_id, private: true)
      )

    [strava_club_id: strava_club_id, club_uuid: club_uuid]
  end

  def import_club_different_profile(%{strava_club_id: strava_club_id, club_uuid: club_uuid}) do
    Router.dispatch(
      build(:import_club,
        club_uuid: club_uuid,
        strava_id: strava_club_id,
        profile: "https://example.com/pictures/clubs/edited.jpg"
      )
    )
  end

  def athlete_join_club(%{athlete_uuid: athlete_uuid, club_uuid: club_uuid}) do
    Router.dispatch(%JoinClub{
      athlete_uuid: athlete_uuid,
      club_uuid: club_uuid
    })
  end

  def strava_athlete_join_club(%{club_uuid: club_uuid}) do
    Router.dispatch(%JoinClub{
      club_uuid: club_uuid,
      athlete_uuid: "athlete-123456"
    })
  end

  def athlete_leave_club(%{athlete_uuid: athlete_uuid, club_uuid: club_uuid}) do
    Router.dispatch(%LeaveClub{
      athlete_uuid: athlete_uuid,
      club_uuid: club_uuid
    })
  end
end
