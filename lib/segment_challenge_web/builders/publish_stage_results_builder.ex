defmodule SegmentChallengeWeb.PublishStageResultsBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Stages.Stage.Commands.PublishStageResults

  def new(conn, _params) do
    %PublishStageResults{
      published_by_athlete_uuid: current_athlete_uuid(conn)
    }
  end

  def build(conn, params) do
    params
    |> assign_published_by_athlete_uuid(conn)
    |> PublishStageResults.new()
  end

  def assign_published_by_athlete_uuid(params, conn),
    do: Map.put(params, :published_by_athlete_uuid, current_athlete_uuid(conn))
end
