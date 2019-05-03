defmodule SegmentChallenge.Events.ChallengeCreated do
  alias SegmentChallenge.Events.ChallengeCreated

  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :name,
    :description,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :hosted_by_club_uuid,
    :hosted_by_club_name,
    :created_by_athlete_uuid,
    :created_by_athlete_name,
    :url_slug,
    challenge_type: "segment",
    restricted_to_club_members?: true,
    allow_private_activities?: false,
    accumulate_activities?: false,
    included_activity_types: [],
    private: false
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    alias SegmentChallenge.NaiveDateTimeParser

    def decode(%ChallengeCreated{} = event) do
      %ChallengeCreated{
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local
      } = event

      %ChallengeCreated{
        event
        | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
          start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local),
          end_date: NaiveDateTimeParser.from_iso8601!(end_date),
          end_date_local: NaiveDateTimeParser.from_iso8601!(end_date_local)
      }
    end
  end
end
