defmodule SegmentChallenge.Events.StageLeaderboardFinalised do
  alias SegmentChallenge.Events.StageLeaderboardFinalised

  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :stage_type,
    :points_adjustment,
    :gender,
    has_goal?: false,
    entries: []
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    import SegmentChallenge.Serialization.Helpers

    def decode(%StageLeaderboardFinalised{} = event) do
      %StageLeaderboardFinalised{entries: entries} = event

      %StageLeaderboardFinalised{event | entries: Enum.map(entries, &decode_entry/1)}
    end

    defp decode_entry(entry) do
      Map.update(entry, :goal_progress, nil, &to_decimal/1)
    end
  end
end
