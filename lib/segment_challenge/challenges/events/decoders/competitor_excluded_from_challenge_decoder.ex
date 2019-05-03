defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.CompetitorExcludedFromChallenge do
  alias SegmentChallenge.Events.CompetitorExcludedFromChallenge
  alias SegmentChallenge.NaiveDateTimeParser

  def decode(%CompetitorExcludedFromChallenge{excluded_at: excluded_at} = event) do
    %CompetitorExcludedFromChallenge{
      event
      | excluded_at: NaiveDateTimeParser.from_iso8601!(excluded_at)
    }
  end
end
