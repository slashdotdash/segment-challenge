defmodule SegmentChallenge.Events.StageLeaderboardCreated do
  alias SegmentChallenge.Events.StageLeaderboardCreated

  @derive Jason.Encoder
  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :stage_type,
    :points_adjustment,
    :name,
    :gender,
    :goal,
    :goal_measure,
    :goal_units,
    rank_by: "elapsed_time_in_seconds",
    rank_order: "asc",
    accumulate_activities?: false,
    has_goal?: false
  ]

  defimpl Commanded.Serialization.JsonDecoder, for: StageLeaderboardCreated do
    def decode(%StageLeaderboardCreated{} = event) do
      %StageLeaderboardCreated{rank_by: rank_by, goal_measure: goal_measure} = event

      %StageLeaderboardCreated{event | goal_measure: goal_measure || rank_by}
    end
  end
end
