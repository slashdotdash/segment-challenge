defmodule SegmentChallenge.Events.StageCreated do
  alias SegmentChallenge.Events.StageCreated
  alias SegmentChallenge.NaiveDateTimeParser

  @derive Jason.Encoder
  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :stage_type,
    :stage_number,
    :name,
    :description,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :points_adjustment,
    :created_by_athlete_uuid,
    :url_slug,
    included_activity_types: ["Run", "Ride", "VirtualRide"],
    allow_private_activities?: false,
    accumulate_activities?: false,
    visible?: false
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(%StageCreated{} = event) do
      %StageCreated{
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local
      } = event

      %StageCreated{
        event
        | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
          start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local),
          end_date: NaiveDateTimeParser.from_iso8601!(end_date),
          end_date_local: NaiveDateTimeParser.from_iso8601!(end_date_local)
      }
    end
  end
end
