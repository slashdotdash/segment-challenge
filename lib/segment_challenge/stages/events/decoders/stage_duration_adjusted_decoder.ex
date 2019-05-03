defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.StageDurationAdjusted do
  alias SegmentChallenge.Events.StageDurationAdjusted
  alias SegmentChallenge.NaiveDateTimeParser

  def decode(
        %StageDurationAdjusted{
          start_date: start_date,
          start_date_local: start_date_local,
          end_date: end_date,
          end_date_local: end_date_local
        } = event
      ) do
    %StageDurationAdjusted{
      event
      | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
        start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local),
        end_date: NaiveDateTimeParser.from_iso8601!(end_date),
        end_date_local: NaiveDateTimeParser.from_iso8601!(end_date_local)
    }
  end
end
