defmodule SegmentChallenge.Commands.Validation.NaiveDateTimeValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok
  def validate(%NaiveDateTime{}, _options), do: :ok
  def validate(_value, _options), do: {:error, "invalid date/time"}
end
