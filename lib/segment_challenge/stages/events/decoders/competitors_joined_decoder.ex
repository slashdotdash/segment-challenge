defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.CompetitorsJoinedStage do
  alias SegmentChallenge.Events.CompetitorsJoinedStage
  alias SegmentChallenge.Events.CompetitorsJoinedStage.Competitor

  def decode(%CompetitorsJoinedStage{competitors: competitors} = event) do
    %CompetitorsJoinedStage{event |
      competitors: map_to_competitor(competitors),
    }
  end

  defp map_to_competitor(enumerable) do
    Enum.map(enumerable, fn competitor -> struct(Competitor, competitor) end)
  end
end
