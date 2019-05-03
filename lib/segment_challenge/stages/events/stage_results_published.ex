defmodule SegmentChallenge.Events.StageResultsPublished do
  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :published_by_athlete_uuid,
    :published_by_club_uuid,
    :message
  ]
end
