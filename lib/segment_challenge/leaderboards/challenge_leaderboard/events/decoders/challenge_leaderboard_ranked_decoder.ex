defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.ChallengeLeaderboardRanked do
  alias SegmentChallenge.Events.ChallengeLeaderboardRanked
  alias SegmentChallenge.Events.ChallengeLeaderboardRanked.Ranking

  def decode(%ChallengeLeaderboardRanked{new_entries: new_entries, positions_gained: positions_gained, positions_lost: positions_lost} = event) do
    %ChallengeLeaderboardRanked{event |
      new_entries: map_to_ranking(new_entries),
      positions_gained: map_to_ranking(positions_gained),
      positions_lost: map_to_ranking(positions_lost),
    }
  end

  defp map_to_ranking(enumerable) do
    Enum.map(enumerable, fn ranking -> struct(Ranking, ranking) end)
  end
end
