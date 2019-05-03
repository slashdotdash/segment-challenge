defmodule SegmentChallenge.Commands.Validation.StageEffortsValidator do
  use Vex.Validator

  def validate([], _options), do: :ok

  def validate(stage_efforts, _options) when is_list(stage_efforts) do
    if Enum.all?(stage_efforts, &Vex.valid?/1) do
      :ok
    else
      {:error, "invalid stage effort"}
    end
  end

  def validate(_stage_efforts, _options), do: {:error, "invalid stage efforts"}
end
