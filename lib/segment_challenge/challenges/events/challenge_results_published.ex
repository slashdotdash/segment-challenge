defmodule SegmentChallenge.Events.ChallengeResultsPublished do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :published_by_athlete_uuid,
    :published_by_club_uuid,
    :message
  ]
end
