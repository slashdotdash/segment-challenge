defmodule SegmentChallenge.Commands.Validation.ActivityTypeValidator do
  use Vex.Validator

  @activity_types SegmentChallenge.Strava.ActivityType.values()

  def validate(nil, _options), do: :ok

  def validate(value, _options) do
    if value in @activity_types do
      :ok
    else
      {:error, "invalid activity type"}
    end
  end
end
