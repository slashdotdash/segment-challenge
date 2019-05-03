defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.ChallengeEnded do
  alias SegmentChallenge.Events.ChallengeEnded
  alias SegmentChallenge.NaiveDateTimeParser

  @doc """
  Parse the end date and end date local local date/times included in the event
  """
  def decode(%ChallengeEnded{end_date: end_date, end_date_local: end_date_local} = event) do
    %ChallengeEnded{
      event
      | end_date: NaiveDateTimeParser.from_iso8601!(end_date),
        end_date_local: NaiveDateTimeParser.from_iso8601!(end_date_local)
    }
  end
end
