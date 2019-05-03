defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.CompetitorsJoinedChallenge do
  alias SegmentChallenge.Events.CompetitorsJoinedChallenge
  alias SegmentChallenge.Events.CompetitorsJoinedChallenge.Competitor

  def decode(%CompetitorsJoinedChallenge{competitors: competitors} = event) do
    %CompetitorsJoinedChallenge{event |
      competitors: map_to_competitor(competitors),
    }
  end

  defp map_to_competitor(enumerable) do
    Enum.map(enumerable, fn competitor -> struct(Competitor, competitor) end)
  end
end
