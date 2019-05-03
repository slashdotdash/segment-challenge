defmodule SegmentChallenge.Athletes.AthleteCommandHandler do
  @behaviour Commanded.Commands.Handler

  alias SegmentChallenge.Commands.{
    ImportAthlete,
    ImportAthleteStarredStravaSegments,
    JoinClub,
    LeaveClub,
    SetAthleteClubMemberships
  }

  alias SegmentChallenge.Athletes.Athlete

  def handle(%Athlete{} = athlete, %ImportAthlete{} = import_athlete) do
    Athlete.import_athlete(athlete, import_athlete)
  end

  def handle(%Athlete{} = athlete, %ImportAthleteStarredStravaSegments{
        starred_segments: starred_segments
      }) do
    Athlete.import_starred_segments(athlete, starred_segments)
  end

  def handle(%Athlete{} = athlete, %SetAthleteClubMemberships{} = set_club_memberships) do
    Athlete.set_club_memberships(athlete, set_club_memberships)
  end

  def handle(%Athlete{} = athlete, %JoinClub{} = join_club) do
    Athlete.join_club(athlete, join_club)
  end

  def handle(%Athlete{} = athlete, %LeaveClub{} = leave_club) do
    Athlete.leave_club(athlete, leave_club)
  end
end
