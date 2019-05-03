defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.PendingAdjustmentInStageLeaderboard do
  alias SegmentChallenge.Events.PendingAdjustmentInStageLeaderboard
  alias SegmentChallenge.NaiveDateTimeParser

  def decode(
        %PendingAdjustmentInStageLeaderboard{
          start_date: start_date,
          start_date_local: start_date_local
        } = event
      ) do
    %PendingAdjustmentInStageLeaderboard{
      event
      | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
        start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local)
    }
  end
end
