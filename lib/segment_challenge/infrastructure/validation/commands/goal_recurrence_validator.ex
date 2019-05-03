defmodule SegmentChallenge.Commands.Validation.GoalRecurrenceValidator do
  use Vex.Validator

  @goal_recurrence ["none", "day", "week", "month"]

  def validate(nil, _options), do: :ok
  def validate(value, _options) when value in @goal_recurrence, do: :ok
  def validate(_value, _options), do: {:error, "invalid goal recurrence"}
end
