defmodule SegmentChallenge.Events.CompetitorLeftChallenge do
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :athlete_uuid,
    :left_at
  ]
end

alias SegmentChallenge.Events.CompetitorLeftChallenge

defimpl Commanded.Serialization.JsonDecoder, for: CompetitorLeftChallenge do
  alias SegmentChallenge.NaiveDateTimeParser

  def decode(%CompetitorLeftChallenge{left_at: left_at} = event) do
    %CompetitorLeftChallenge{event | left_at: NaiveDateTimeParser.from_iso8601!(left_at)}
  end
end
