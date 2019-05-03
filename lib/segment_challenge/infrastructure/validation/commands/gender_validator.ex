defmodule SegmentChallenge.Commands.Validation.GenderValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok
  def validate("M", _options), do: :ok
  def validate("F", _options), do: :ok
  def validate(_value, _options), do: {:error, "missing gender"}
end
