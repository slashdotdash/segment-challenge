defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.CompetitorRemovedFromStage do
  alias SegmentChallenge.Events.CompetitorRemovedFromStage
  alias SegmentChallenge.NaiveDateTimeParser

  def decode(%CompetitorRemovedFromStage{removed_at: removed_at} = event) do
    %CompetitorRemovedFromStage{event | removed_at: NaiveDateTimeParser.from_iso8601!(removed_at)}
  end
end
