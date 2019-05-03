defmodule SegmentChallenge.Commands.Validation.UnitsValidator do
  use Vex.Validator

  @distance_units ["feet", "kilometres", "metres", "miles"]
  @time_units ["seconds", "minutes", "hours", "days"]

  def validate(nil, _options), do: :ok

  def validate(value, _options) when value in @distance_units, do: :ok
  def validate(value, _options) when value in @time_units, do: :ok

  def validate(_value, _options), do: {:error, "invalid goal units"}
end
