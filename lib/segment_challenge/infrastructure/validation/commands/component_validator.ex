defmodule SegmentChallenge.Commands.Validation.ComponentValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok
  def validate(component, options), do: Vex.validate(component, options)
end
