defmodule SegmentChallenge.Events.CompetitorsJoinedStage do
  defmodule Competitor do
    @derive Jason.Encoder
    defstruct [
      :athlete_uuid,
      :gender
    ]
  end

  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    competitors: []
  ]
end
