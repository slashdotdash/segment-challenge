defmodule SegmentChallenge.Events.StageLeaderboardAdjusted do
  alias SegmentChallenge.Events.StageLeaderboardAdjusted

  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :stage_type,
    :points_adjustment,
    :gender,
    previous_entries: [],
    adjusted_entries: []
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    import SegmentChallenge.Serialization.Helpers

    def decode(%StageLeaderboardAdjusted{} = event) do
      %StageLeaderboardAdjusted{
        previous_entries: previous_entries,
        adjusted_entries: adjusted_entries
      } = event

      %StageLeaderboardAdjusted{
        event
        | previous_entries: Enum.map(previous_entries, &decode_entry/1),
          adjusted_entries: Enum.map(adjusted_entries, &decode_entry/1)
      }
    end

    defp decode_entry(entry) do
      Map.update(entry, :goal_progress, nil, &to_decimal/1)
    end
  end
end
