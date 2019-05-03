defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.StageStarted do
  alias SegmentChallenge.Events.StageStarted
  alias SegmentChallenge.NaiveDateTimeParser

  @doc """
  Parse the start date and start date local date/times included in the event
  """
  def decode(%StageStarted{start_date: start_date, start_date_local: start_date_local} = event) do
    %StageStarted{
      event
      | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
        start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local)
    }
  end
end
