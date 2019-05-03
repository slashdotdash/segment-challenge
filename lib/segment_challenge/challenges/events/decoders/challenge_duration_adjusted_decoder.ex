defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.ChallengeDurationAdjusted do
  alias SegmentChallenge.Events.ChallengeDurationAdjusted
  alias SegmentChallenge.NaiveDateTimeParser

  def decode(%ChallengeDurationAdjusted{} = event) do
    %ChallengeDurationAdjusted{
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = event

    %ChallengeDurationAdjusted{
      event
      | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
        start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local),
        end_date: NaiveDateTimeParser.from_iso8601!(end_date),
        end_date_local: NaiveDateTimeParser.from_iso8601!(end_date_local)
    }
  end
end
