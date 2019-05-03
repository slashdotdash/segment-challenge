defmodule SegmentChallenge.Events.CompetitorsJoinedChallenge do
  defmodule Competitor do
    @derive Jason.Encoder
    defstruct [
      :athlete_uuid,
      :firstname,
      :lastname,
      :gender
    ]
  end

  @derive Jason.Encoder
  defstruct [:challenge_uuid, competitors: []]
end
