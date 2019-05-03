defmodule SegmentChallengeWeb.Helpers.ChallengeHelpers do
  alias SegmentChallenge.Projections.ChallengeProjection

  def is_challenge_host?(conn, %ChallengeProjection{} = challenge) do
    %{assigns: %{current_athlete: current_athlete}} = conn
    %ChallengeProjection{created_by_athlete_uuid: created_by_athlete_uuid} = challenge

    case current_athlete do
      %{athlete_uuid: ^created_by_athlete_uuid} -> true
      _ -> false
    end
  end

  def is_challenge_competitor?(conn, %ChallengeProjection{} = challenge) do
    %{assigns: %{joined_challenges: joined_challenges}} = conn
    %ChallengeProjection{challenge_uuid: challenge_uuid} = challenge

    MapSet.member?(joined_challenges, challenge_uuid)
  end

  def is_past_challenge?(%ChallengeProjection{status: "past"}), do: true
  def is_past_challenge?(%ChallengeProjection{}), do: false

  def is_virtual_race?(%ChallengeProjection{challenge_type: "race"}), do: true
  def is_virtual_race?(%ChallengeProjection{}), do: false

  @doc """
  Strava calculates an athlete's best effort at the following distances for run
  actvities.

    Name        Distance (metres)
    "400m"          400
    "1/2 mile"      805
    "1k"           1000
    "1 mile"       1609
    "2 mile"       3219
    "5k"           5000
    "10k"         10000
    "15k"         15000
    "10 mile"     16090
    "20K"         20000

  """
  def is_best_effort_distance?(%ChallengeProjection{has_goal: true} = challenge) do
    %ChallengeProjection{goal: goal, goal_units: units} = challenge

    if is_run_challenge?(challenge) do
      case {goal, units} do
        {400.0, "metres"} -> true
        {0.5, "miles"} -> true
        {1_000.0, "metres"} -> true
        {1.0, "kilometres"} -> true
        {1.0, "miles"} -> true
        {2.0, "miles"} -> true
        {5.0, "kilometres"} -> true
        {5_000.0, "metres"} -> true
        {10.0, "kilometres"} -> true
        {10_000.0, "metres"} -> true
        {15.0, "kilometres"} -> true
        {15_000.0, "metres"} -> true
        {10.0, "miles"} -> true
        {20.0, "kilometres"} -> true
        {20_000.0, "metres"} -> true
        {_goal, _units} -> false
      end
    else
      false
    end
  end

  def is_best_effort_distance?(%ChallengeProjection{}), do: false

  def is_ride_challenge?(%ChallengeProjection{included_activity_types: nil}), do: false

  def is_ride_challenge?(%ChallengeProjection{} = challenge) do
    %ChallengeProjection{included_activity_types: included_activity_types} = challenge

    Enum.member?(included_activity_types, "Ride")
  end

  def is_run_challenge?(%ChallengeProjection{included_activity_types: nil}), do: false

  def is_run_challenge?(%ChallengeProjection{} = challenge) do
    %ChallengeProjection{included_activity_types: included_activity_types} = challenge

    Enum.member?(included_activity_types, "Run")
  end

  defdelegate hide_challenge_stages?(challenge), to: ChallengeProjection

  def display_challenge_type(challenge_type)
  def display_challenge_type("segment"), do: "Segment Challenge"
  def display_challenge_type("distance"), do: "Distance Challenge"
  def display_challenge_type("elevation"), do: "Elevation Challenge"
  def display_challenge_type("duration"), do: "Duration Challenge"
  def display_challenge_type("race"), do: "Virtual Race"

  def display_excluded_activities(%ChallengeProjection{} = challenge) do
    %ChallengeProjection{included_activity_types: included_activity_types} = challenge

    ride? = Enum.member?(included_activity_types, "Ride")
    run? = Enum.member?(included_activity_types, "Run")

    cond do
      ride? && run? ->
        "Manual entries, e-bike rides, trainer rides, and treadmill runs are not eligible."

      ride? ->
        "Manual entries, e-bike rides, and trainer rides are not eligible."

      run? ->
        "Manual entries, virtual runs, and treadmill runs are not eligible."

      true ->
        "Manual entries are not eligible."
    end
  end
end
