defmodule SegmentChallenge.Commands.ImportAthleteStarredStravaSegments do
  defstruct [
    :athlete_uuid,
    :starred_segments
  ]

  use Vex.Struct

  validates(:athlete_uuid, uuid: true)
  validates(:starred_segments, by: &is_list/1)
end
