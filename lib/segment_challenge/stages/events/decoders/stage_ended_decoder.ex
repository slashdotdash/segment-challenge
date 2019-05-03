defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.StageEnded do
  alias SegmentChallenge.Events.StageEnded
  alias SegmentChallenge.NaiveDateTimeParser

  @doc """
  Parse the end date and end date local date/times included in the event
  """
  def decode(%StageEnded{end_date: end_date, end_date_local: end_date_local} = event) do
    %StageEnded{
      event
      | end_date: NaiveDateTimeParser.from_iso8601!(end_date),
        end_date_local: NaiveDateTimeParser.from_iso8601!(end_date_local)
    }
  end
end
