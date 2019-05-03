defmodule SegmentChallenge.Stages.Stage.Commands.CreateRaceStage do
  alias SegmentChallenge.Challenges.Services.UrlSlugs.UniqueSlugger

  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :stage_number,
    :stage_type,
    :name,
    :description,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :allow_private_activities,
    :included_activity_types,
    :goal,
    :goal_units,
    :created_by_athlete_uuid,
    visible: true,
    slugger: &UniqueSlugger.slugify/3
  ]

  use ExConstructor
  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:challenge_uuid, uuid: true)
  validates(:stage_number, presence: true, by: &is_integer/1)
  validates(:stage_type, presence: true, stage_type: true)
  validates(:name, presence: true, string: true)
  validates(:description, string: true)
  validates(:start_date, presence: true, naivedatetime: true)
  validates(:start_date_local, presence: true, naivedatetime: true)
  validates(:end_date, presence: true, naivedatetime: true, futuredate: true)
  validates(:end_date_local, presence: true, naivedatetime: true)

  validates(:allow_private_activities,
    by: [function: &is_boolean/1, allow_nil: false, message: "must be present"]
  )

  validates(:included_activity_types,
    presence: [message: "at least one activity type must be selected"],
    activity_types: true
  )

  validates(:goal, presence: true, by: [function: &is_float/1, allow_nil: true])
  validates(:goal_units, presence: true, units: true)
  validates(:visible, by: [function: &is_boolean/1, allow_nil: false])
  validates(:created_by_athlete_uuid, uuid: true)
  validates(:slugger, by: &is_function/1)
end
