defmodule SegmentChallenge.Commands.CreateStageLeaderboard do
  @allowed_measurements [
    "elapsed_time_in_seconds",
    "distance_in_metres",
    "moving_time_in_seconds",
    "elevation_gain_in_metres"
  ]

  defstruct [
    :stage_leaderboard_uuid,
    :challenge_uuid,
    :stage_uuid,
    :stage_type,
    :points_adjustment,
    :name,
    :gender,
    :rank_by,
    :rank_order,
    :accumulate_activities,
    :has_goal,
    :goal_measure,
    :goal,
    :goal_units
  ]

  use Vex.Struct

  validates(:stage_leaderboard_uuid, uuid: true)
  validates(:challenge_uuid, uuid: true)
  validates(:stage_uuid, uuid: true)
  validates(:stage_type, presence: true, stage_type: true)
  validates(:points_adjustment, pointsadjustment: true)
  validates(:name, presence: true, string: true)
  validates(:gender, presence: true, gender: true)
  validates(:rank_by, presence: true, inclusion: @allowed_measurements)
  validates(:rank_order, presence: true, inclusion: ["asc", "desc"])
  validates(:accumulate_activities, by: [function: &is_boolean/1, allow_nil: false])
  validates(:has_goal, by: [function: &is_boolean/1, allow_nil: false])
  validates(:goal_measure, presence: [if: [has_goal: true]], inclusion: @allowed_measurements)

  validates(:goal, presence: [if: [has_goal: true]], by: [function: &is_number/1, allow_nil: true])

  validates(:goal_units, presence: [if: [has_goal: true]], string: true)
end
