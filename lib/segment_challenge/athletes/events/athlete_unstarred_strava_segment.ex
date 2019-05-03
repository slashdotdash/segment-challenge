defmodule SegmentChallenge.Events.AthleteUnstarredStravaSegment do
  @derive Jason.Encoder
  defstruct [
    :athlete_uuid,
    :strava_segment_id,
  ]
end
