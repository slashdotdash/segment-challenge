defmodule SegmentChallengeWeb.PublishChallengeResultsBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Commands.PublishChallengeResults

  def new(conn, _params) do
    %PublishChallengeResults{
      published_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_published_by_athlete_uuid(conn)
    |> PublishChallengeResults.new()
  end

  def assign_published_by_athlete_uuid(params, conn),
    do: Map.put(params, :published_by_athlete_uuid, current_athlete_uuid(conn))
end
