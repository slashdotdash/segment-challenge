defmodule SegmentChallenge.Events.ChallengeLeaderboardRanked do
  defmodule Ranking do
    @derive Jason.Encoder
    defstruct [
      :athlete_uuid,
      :rank,
      :positions_changed
    ]
  end

  @derive Jason.Encoder
  defstruct [
    :challenge_leaderboard_uuid,
    new_entries: [],
    positions_gained: [],
    positions_lost: [],
    has_goal?: false
  ]
end
