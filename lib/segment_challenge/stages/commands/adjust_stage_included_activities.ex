defmodule SegmentChallenge.Stages.Stage.Commands.AdjustStageIncludedActivities do
  defstruct [
    :stage_uuid,
    :included_activity_types
  ]

  use Vex.Struct

  validates(:stage_uuid, uuid: true)

  validates(:included_activity_types,
    presence: [
      message: "at least one activity type must be included"
    ],
    activity_types: true
  )
end
