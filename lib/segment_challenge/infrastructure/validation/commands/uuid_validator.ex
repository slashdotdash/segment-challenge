defmodule SegmentChallenge.Commands.Validation.UuidValidator do
  use Vex.Validator

  def validate(value, _options) do
    Vex.Validators.By.validate(value,
      function: &String.valid?/1,
      allow_nil: false,
      allow_blank: false
    )
  end
end
