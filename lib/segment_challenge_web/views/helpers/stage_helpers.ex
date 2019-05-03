defmodule SegmentChallengeWeb.Helpers.StageHelpers do
  alias SegmentChallenge.Projections.StageProjection

  def is_past?(%StageProjection{status: "past"}), do: true
  def is_past?(%StageProjection{}), do: false

  def is_race_stage?(%StageProjection{stage_type: "race"}), do: true
  def is_race_stage?(%StageProjection{}), do: false

  def is_activity_stage?(%StageProjection{stage_type: stage_type})
      when stage_type in ["distance", "duration", "elevation"],
      do: true

  def is_activity_stage?(%StageProjection{}), do: false

  def is_ride_stage?(%StageProjection{included_activity_types: nil}), do: false

  def is_ride_stage?(%StageProjection{} = challenge) do
    %StageProjection{included_activity_types: included_activity_types} = challenge

    Enum.member?(included_activity_types, "Ride")
  end

  def is_run_stage?(%StageProjection{included_activity_types: nil}), do: false

  def is_run_stage?(%StageProjection{} = challenge) do
    %StageProjection{included_activity_types: included_activity_types} = challenge

    Enum.member?(included_activity_types, "Run")
  end
end
