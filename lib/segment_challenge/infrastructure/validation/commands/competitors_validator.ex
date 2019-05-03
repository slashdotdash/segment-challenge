defmodule SegmentChallenge.Commands.Validation.CompetitorsValidator do
  use Vex.Validator

  def validate([], _options), do: :ok
  def validate(competitors, options) when is_list(competitors) do
    case Enum.find(competitors, fn competitor -> !Vex.valid?(competitor) end) do
      nil -> :ok
      competitor -> Vex.validate(competitor, options)
    end
  end
  def validate(_value, _options), do: {:error, "invalid competitor list"}
end
