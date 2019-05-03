defmodule SegmentChallenge.Commands.CreateChallenge do
  alias SegmentChallenge.Commands.CreateChallenge
  alias SegmentChallenge.Commands.CreateChallenge.ChallengeStage
  alias SegmentChallenge.Challenges.Services.UrlSlugs.UniqueSlugger

  defstruct [
    :challenge_uuid,
    :challenge_type,
    :name,
    :description,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :restricted_to_club_members,
    :allow_private_activities,
    :included_activity_types,
    :accumulate_activities,
    :has_goal,
    :goal,
    :goal_units,
    :goal_recurrence,
    :stages,
    :hosted_by_club_uuid,
    :hosted_by_club_name,
    :created_by_athlete_uuid,
    :created_by_athlete_name,
    private: false,
    slugger: &UniqueSlugger.slugify/3
  ]

  defmodule ChallengeStage do
    defstruct [
      :name,
      :description,
      :stage_number,
      :start_date,
      :start_date_local,
      :end_date,
      :end_date_local
    ]

    use ExConstructor
    use Vex.Struct

    validates(:name, presence: true, string: true)
    validates(:description, string: true)
    validates(:stage_number, presence: true, by: &is_number/1)
    validates(:start_date, presence: true, naivedatetime: true)
    validates(:start_date_local, presence: true, naivedatetime: true)
    validates(:end_date, presence: true, naivedatetime: true, futuredate: true)
    validates(:end_date_local, presence: true, naivedatetime: true)
  end

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:challenge_type, presence: true, challenge_type: true)
  validates(:name, presence: true, string: true)
  validates(:description, presence: true, string: true)
  validates(:start_date, presence: true, naivedatetime: true)
  validates(:start_date_local, presence: true, naivedatetime: true)
  validates(:end_date, presence: true, naivedatetime: true, futuredate: true)
  validates(:end_date_local, presence: true, naivedatetime: true)

  validates(:restricted_to_club_members,
    by: [function: &is_boolean/1, allow_nil: false, message: "must be present"]
  )

  validates(:allow_private_activities,
    by: [function: &is_boolean/1, allow_nil: false, message: "must be present"]
  )

  validates(:included_activity_types,
    presence: [
      unless: [challenge_type: "segment"],
      message: "at least one activity type must be selected"
    ],
    activity_types: true
  )

  validates(:accumulate_activities, by: &CreateChallenge.validate_accumulate_activities/2)

  validates(:has_goal, by: &CreateChallenge.validate_has_goal/2)
  validates(:goal, presence: [if: [has_goal: true]], by: [function: &is_float/1, allow_nil: true])
  validates(:goal_units, presence: [if: [has_goal: true]], units: true)
  validates(:goal_recurrence, presence: [if: [has_goal: true]], goal_recurrence: true)

  validates(:hosted_by_club_uuid, uuid: true)
  validates(:hosted_by_club_name, presence: true, string: true)
  validates(:created_by_athlete_uuid, uuid: true)
  validates(:created_by_athlete_name, presence: true, string: true)

  validates(:stages,
    presence: [if: &CreateChallenge.stages_required?/1],
    component_list: [message: "cannot end in the past"]
  )

  def new(data, args) do
    %CreateChallenge{stages: stages} = command = super(data, args)

    %CreateChallenge{command | stages: Enum.map(stages, &ChallengeStage.new/1)}
  end

  def validate_has_goal(_value, %{challenge_type: "segment"}), do: :ok

  def validate_has_goal(value, _context) do
    case is_boolean(value) do
      true -> :ok
      false -> {:error, "must be present"}
    end
  end

  def validate_accumulate_activities(_value, %{challenge_type: "segment"}), do: :ok

  def validate_accumulate_activities(value, _context) do
    case is_boolean(value) do
      true -> :ok
      false -> {:error, "must be present"}
    end
  end

  def stages_required?(%CreateChallenge{has_goal: true, goal_recurrence: goal_recurrence})
      when goal_recurrence in ["day", "week", "month"],
      do: true

  def stages_required?(%CreateChallenge{}), do: false
end
