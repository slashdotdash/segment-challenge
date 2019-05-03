defmodule SegmentChallenge.Commands.ApproveChallengeLeaderboards do
  defstruct [
    :challenge_uuid,
    :approved_by_athlete_uuid,
    :approved_by_club_uuid,
    :approval_message,
  ]

  use ExConstructor
  use Vex.Struct

  alias SegmentChallenge.Challenges.Challenges.Validators.ApproveChallengeLeaderboards

  validates :challenge_uuid, uuid: true
  validates :approved_by_athlete_uuid, uuid: true
  validates :approved_by_club_uuid, uuid: true
  validates :approval_message, string: true, by: &ApproveChallengeLeaderboards.validate/2
end
