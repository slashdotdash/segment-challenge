defmodule SegmentChallenge.Stages.Validators.StageNumber do
  alias SegmentChallenge.Challenges.ChallengeStageService

  def validate(stage_number, context) when is_integer(stage_number) do
    challenge_uuid = Map.get(context, :challenge_uuid)

    next_stage = ChallengeStageService.next_stage(challenge_uuid)
    expected_stage_number = next_stage.stage_number

    if stage_number == expected_stage_number do
      :ok
    else
      if stage_number < expected_stage_number do
        stage_numbers =
          challenge_uuid
          |> ChallengeStageService.challenge_stages()
          |> Enum.map(&(&1.stage_number))
          |> MapSet.new()

        case MapSet.member?(stage_numbers, stage_number) do
          true -> {:error, "duplicate stage number"}
          false -> :ok
        end
      else
        {:error, "invalid stage number"}
      end
    end
  end

  def validate(_stage_number, _context), do: {:error, "must be a number"}
end
