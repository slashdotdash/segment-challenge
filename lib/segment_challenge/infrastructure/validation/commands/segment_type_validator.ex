defmodule SegmentChallenge.Commands.Validation.SegmentTypeValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok

  # Segment types
  def validate("mountain", _options), do: :ok
  def validate("flat", _options), do: :ok
  def validate("rolling", _options), do: :ok

  def validate(_value, _options), do: {:error, "invalid segment type"}
end
