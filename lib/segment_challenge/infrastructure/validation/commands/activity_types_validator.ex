defmodule SegmentChallenge.Commands.Validation.ActivityTypesValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok

  @activity_types SegmentChallenge.Strava.ActivityType.values()

  def validate(value, _options) when is_list(value) do
    if Enum.all?(value, &valid_activity_type?/1) do
      :ok
    else
      {:error, "invalid activity type"}
    end
  end

  def validate(_value, _options), do: {:error, "invalid activity types"}

  defp valid_activity_type?(value) when value in @activity_types, do: true
  defp valid_activity_type?(_value), do: false
end
