defmodule SegmentChallenge.Stages.Stage.Commands.IncludeCompetitorsInStage do
  defmodule Competitor do
    defstruct [:athlete_uuid, :gender]

    use Vex.Struct

    validates(:athlete_uuid, uuid: true)
    # Gender is optional (it may be `nil`)
    validates(:gender, gender: true)
  end

  defmodule LimitedCompetitor do
    defstruct [:athlete_uuid, :reason]
  end

  defstruct [:stage_uuid, competitors: [], limited_competitors: []]

  use Vex.Struct

  validates(:stage_uuid, uuid: true)
  validates(:competitors, competitors: true)
  validates(:limited_competitors, &is_list/1)
end
