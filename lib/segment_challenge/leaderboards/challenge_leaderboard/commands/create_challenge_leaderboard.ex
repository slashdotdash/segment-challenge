defmodule SegmentChallenge.Commands.CreateChallengeLeaderboard do
  defstruct [
    :challenge_leaderboard_uuid,
    :challenge_uuid,
    :challenge_type,
    :name,
    :description,
    :gender,
    :points,
    :rank_by,
    :rank_order,
    :has_goal
  ]

  use Vex.Struct

  validates(:challenge_leaderboard_uuid, uuid: true)
  validates(:challenge_uuid, uuid: true)
  validates(:challenge_type, presence: true, challenge_type: true)
  validates(:name, presence: true, string: true)
  validates(:description, presence: true, string: true)
  validates(:gender, presence: true, gender: true)
  validates(:points, presence: [if: [challenge_type: "segment"]])

  validates(:rank_by,
    presence: true,
    inclusion: [
      "points",
      "goals",
      "elapsed_time_in_seconds",
      "distance_in_metres",
      "moving_time_in_seconds",
      "elevation_gain_in_metres"
    ]
  )

  validates(:rank_order, presence: true, inclusion: ["asc", "desc"])
  validates(:has_goal, by: [function: &is_boolean/1, allow_nil: false])
end
