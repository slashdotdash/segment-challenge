defmodule SegmentChallenge.Commands.Validation.ChallengeTypeValidator do
  use Vex.Validator

  @challenge_types ["distance", "duration", "elevation", "segment", "race"]

  def validate(nil, _options), do: :ok
  def validate(value, _options) when value in @challenge_types, do: :ok
  def validate(_value, _options), do: {:error, "invalid challenge type"}
end
