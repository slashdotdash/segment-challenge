defmodule SegmentChallenge.Commands.Validation.StageTypeValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok

  # Activity stage types
  def validate("distance", _options), do: :ok
  def validate("duration", _options), do: :ok
  def validate("elevation", _options), do: :ok

  # Segment stage types
  def validate("mountain", _options), do: :ok
  def validate("flat", _options), do: :ok
  def validate("rolling", _options), do: :ok

  # Virtual race stage type
  def validate("race", _options), do: :ok

  def validate(_value, _options), do: {:error, "invalid stage type"}
end
