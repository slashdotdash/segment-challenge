defmodule SegmentChallenge.Commands.AdjustChallengeIncludedActivities do
  defstruct [
    :challenge_uuid,
    :included_activity_types
  ]

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)

  validates(:included_activity_types,
    presence: [
      message: "at least one activity type must be included"
    ],
    activity_types: true
  )
end
