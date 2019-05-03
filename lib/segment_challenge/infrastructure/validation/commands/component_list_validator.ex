defmodule SegmentChallenge.Commands.Validation.ComponentListValidator do
  use Vex.Validator

  require Logger

  def validate(nil, _options), do: :ok
  def validate([], _options), do: :ok

  def validate(value, options) when is_list(value) do
    if Enum.all?(value, &Vex.valid?/1) do
      :ok
    else
      {:error, error_message(options)}
    end
  end

  def validate(_value, options) do
    {:error, error_message(options)}
  end

  defp error_message(options),
    do: Keyword.get(options, :message, "invalid item")
end
