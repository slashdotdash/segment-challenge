defmodule SegmentChallenge.Events.ChallengeIncludedActivitiesAdjusted do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :included_activity_types
  ]
end
