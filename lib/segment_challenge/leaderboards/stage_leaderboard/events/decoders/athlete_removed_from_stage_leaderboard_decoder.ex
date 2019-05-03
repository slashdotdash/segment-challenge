defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.AthleteRemovedFromStageLeaderboard do
  alias SegmentChallenge.Events.AthleteRemovedFromStageLeaderboard
  alias SegmentChallenge.NaiveDateTimeParser

  def decode(%AthleteRemovedFromStageLeaderboard{removed_at: removed_at} = event) do
    %AthleteRemovedFromStageLeaderboard{
      event
      | removed_at: NaiveDateTimeParser.from_iso8601!(removed_at)
    }
  end
end
