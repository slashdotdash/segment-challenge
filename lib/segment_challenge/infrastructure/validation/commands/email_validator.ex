defmodule SegmentChallenge.Commands.Validation.EmailValidator do
  use Vex.Validator

  def validate(nil, _options), do: :ok

  def validate(value, _options) do
    if Regex.match?(~r/.+@.+/, value) do
      :ok
    else
      {:error, "invalid email"}
    end
  end
end
