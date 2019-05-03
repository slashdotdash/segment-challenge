defmodule SegmentChallenge.Events.ChallengeStageRequested do
  alias SegmentChallenge.Events.ChallengeStageRequested

  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    :stage_uuid,
    :stage_number,
    :stage_type,
    :name,
    :description,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :allow_private_activities?,
    :included_activity_types,
    :accumulate_activities?,
    :has_goal?,
    :goal,
    :goal_units,
    :visible?,
    :created_by_athlete_uuid
  ]

  defimpl Commanded.Serialization.JsonDecoder do
    alias SegmentChallenge.NaiveDateTimeParser

    def decode(%ChallengeStageRequested{} = event) do
      %ChallengeStageRequested{
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local
      } = event

      %ChallengeStageRequested{
        event
        | start_date: NaiveDateTimeParser.from_iso8601!(start_date),
          start_date_local: NaiveDateTimeParser.from_iso8601!(start_date_local),
          end_date: NaiveDateTimeParser.from_iso8601!(end_date),
          end_date_local: NaiveDateTimeParser.from_iso8601!(end_date_local)
      }
    end
  end
end
