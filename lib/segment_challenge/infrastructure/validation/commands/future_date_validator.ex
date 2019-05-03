defmodule SegmentChallenge.Commands.Validation.FutureDateValidator do
  @moduledoc """
  Ensure the given date is in the future
  """

  use Vex.Validator

  def validate(%NaiveDateTime{} = date, _options) do
    case Timex.after?(date, utc_now()) do
      true -> :ok
      false -> {:error, "must be a date in the future"}
    end
  end

  def validate(_value, _options), do: :ok

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()
end
