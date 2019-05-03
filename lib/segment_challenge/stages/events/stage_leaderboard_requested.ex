defmodule SegmentChallenge.Events.StageLeaderboardRequested do
  alias SegmentChallenge.Events.StageLeaderboardRequested

  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :name,
    :gender,
    :stage_type,
    :points_adjustment,
    :goal_measure,
    :goal,
    :goal_units,
    accumulate_activities?: false,
    rank_by: "elapsed_time_in_seconds",
    rank_order: "asc",
    has_goal?: false
  ]

  defimpl Commanded.Serialization.JsonDecoder, for: StageLeaderboardRequested do
    def decode(%StageLeaderboardRequested{} = event) do
      %StageLeaderboardRequested{rank_by: rank_by, goal_measure: goal_measure} = event

      %StageLeaderboardRequested{event | goal_measure: goal_measure || rank_by}
    end
  end
end
