defmodule SegmentChallenge.Events.AthleteRemovedFromChallengeLeaderboard do
  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    :athlete_uuid,
    :rank,
  ]
end
