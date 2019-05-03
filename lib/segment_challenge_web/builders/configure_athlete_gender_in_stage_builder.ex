defmodule SegmentChallengeWeb.ConfigureAthleteGenderInStageBuilder do
  import SegmentChallengeWeb.Builders.CurrentAthleteHelper

  alias SegmentChallenge.Stages.Stage.Commands.ConfigureAthleteGenderInStage

  def new(conn, _params) do
    %ConfigureAthleteGenderInStage{athlete_uuid: current_athlete_uuid(conn)}
  end

  def build(conn, params) do
    params
    |> assign_athlete_uuid(conn)
    |> ConfigureAthleteGenderInStage.new()
  end
end
