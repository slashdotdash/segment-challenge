defmodule SegmentChallenge.Clubs.Club do
  @moduledoc """
  Clubs represent groups of athletes.
  """

  defstruct [
    :club_uuid,
    :strava_id,
    :name,
    :description,
    :sport_type,
    :city,
    :country,
    :profile,
    :website,
    :state,
    private: false
  ]

  alias SegmentChallenge.Commands.ImportClub
  alias SegmentChallenge.Events.{ClubImported, ClubProfileChanged}
  alias SegmentChallenge.Clubs.Club

  def identity(strava_id), do: "club-#{strava_id}"

  @doc """
  Import a club from Strava.
  """
  def execute(club, import_club_command)

  def execute(%Club{state: state, strava_id: strava_id}, %ImportClub{} = command)
      when state == nil or strava_id == nil do
    %ImportClub{
      club_uuid: club_uuid,
      strava_id: strava_id,
      name: name,
      description: description,
      sport_type: sport_type,
      city: city,
      state: state,
      country: country,
      profile: profile,
      private: private
    } = command

    %ClubImported{
      club_uuid: club_uuid,
      strava_id: strava_id,
      name: name,
      description: description,
      sport_type: sport_type,
      city: city,
      state: state,
      country: country,
      profile: profile,
      private: private
    }
  end

  def execute(%Club{} = club, %ImportClub{} = command) do
    %Club{club_uuid: club_uuid, strava_id: strava_id, profile: profile} = club
    %ImportClub{profile: strava_profile} = command

    if profile != strava_profile do
      %ClubProfileChanged{
        club_uuid: club_uuid,
        strava_id: strava_id,
        profile: strava_profile
      }
    else
      # Club already imported & nothing changed
      []
    end
  end

  # State mutators

  def apply(%Club{} = club, %ClubImported{} = club_imported) do
    %Club{
      club
      | club_uuid: club_imported.club_uuid,
        strava_id: club_imported.strava_id,
        name: club_imported.name,
        description: club_imported.description,
        sport_type: club_imported.sport_type,
        city: club_imported.city,
        country: club_imported.country,
        profile: club_imported.profile,
        website: club_imported.website,
        private: club_imported.private,
        state: :imported
    }
  end

  def apply(%Club{} = club, %ClubProfileChanged{profile: profile}) do
    %Club{club | profile: profile}
  end

  # Ignore obsolete member joined/left events
  def apply(%Club{} = club, _event), do: club
end
