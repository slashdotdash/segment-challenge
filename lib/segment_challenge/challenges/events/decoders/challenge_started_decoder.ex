defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.ChallengeStarted do
  alias SegmentChallenge.Events.ChallengeStarted
  alias SegmentChallenge.NaiveDateTimeParser

  @doc """
  Parse the start date and start date local local date/times included in the event
  """
  def decode(
        %ChallengeStarted{start_date: start_date, start_date_local: start_date_local} = event
      ) do
    %ChallengeStarted{
      event
      | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
        start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local)
    }
  end
end
