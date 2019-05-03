defmodule SegmentChallenge.Events.ChallengeGoalConfigured do
  defmodule GoalRecurrence do
    use Exnumerator,
      values: [
        "none",
        "day",
        "week",
        "month"
      ]
  end

  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :goal,
    :goal_units,
    :goal_recurrence
  ]
end
