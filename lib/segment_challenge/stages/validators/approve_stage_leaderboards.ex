defmodule SegmentChallenge.Stages.Validators.ApproveStageLeaderboards do
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Repo

  @doc """
  Ensure that all stages before the current stage have already been approved
  """
  def validate(_approval_message, context) do
    stage_uuid = Map.get(context, :stage_uuid)
    challenge_uuid = Map.get(context, :challenge_uuid)

    stages =
      challenge_uuid
      |> StagesInChallengeQuery.new()
      |> Repo.all()

    current_stage = Enum.find(stages, fn stage -> stage.stage_uuid == stage_uuid end)
    previous_stages = Enum.filter(stages, fn stage -> stage.stage_number < current_stage.stage_number end)

    case Enum.all?(previous_stages, &(&1.approved)) do
      true -> :ok
      _ -> {:error, "all previous stages must be approved"}
    end
  end
end
