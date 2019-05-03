defmodule SegmentChallenge.Challenges.Formatters.DistanceFormatter do
  def distance(distance_in_metres) do
    case distance_in_metres do
      metres when metres < 1_000 -> "#{metres} metres"
      metres -> "#{Float.round(metres / 1_000, 1)}km"
    end
  end

  @doc """
  Convert goal to distance in metres.
  """
  def goal_in_metres(goal, units)
  def goal_in_metres(goal, "metres"), do: Decimal.from_float(goal)

  def goal_in_metres(goal, "kilometres"),
    do: Decimal.mult(Decimal.from_float(goal), Decimal.new(1_000))

  def goal_in_metres(goal, "feet"),
    do: Decimal.mult(Decimal.from_float(goal), Decimal.from_float(0.3048))

  def goal_in_metres(goal, "miles"),
    do: Decimal.mult(Decimal.from_float(goal), Decimal.new(1609))

  @doc """
  Convert goal to time in seconds.
  """
  def goal_in_seconds(goal, units)
  def goal_in_seconds(goal, "seconds"), do: Decimal.from_float(goal)

  def goal_in_seconds(goal, "minutes"),
    do: Decimal.mult(Decimal.from_float(goal), Decimal.new(60))

  def goal_in_seconds(goal, "hours"),
    do: Decimal.mult(Decimal.from_float(goal), Decimal.new(3_600))

  def goal_in_seconds(goal, "days"),
    do: Decimal.mult(Decimal.from_float(goal), Decimal.new(86_400))
end
