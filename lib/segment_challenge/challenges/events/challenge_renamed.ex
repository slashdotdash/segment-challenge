defmodule SegmentChallenge.Events.ChallengeRenamed do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :name,
    :url_slug,
    :renamed_by_athlete_uuid,
  ]
end
