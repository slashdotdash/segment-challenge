defmodule SegmentChallenge.Commands.Validation.PointsAdjustmentValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok
  def validate("double", _options), do: :ok
  def validate("preview", _options), do: :ok
  def validate("queen", _options), do: :ok
  def validate(_value, _options), do: {:error, "invalid points adjustment"}
end
