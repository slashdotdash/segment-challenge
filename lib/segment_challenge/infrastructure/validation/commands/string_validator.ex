defmodule SegmentChallenge.Commands.Validation.SringValidator do
  use Vex.Validator

  def validate(value, _options) do
    Vex.Validators.By.validate(value,
      function: &String.valid?/1,
      allow_nil: true,
      allow_blank: true
    )
  end
end
