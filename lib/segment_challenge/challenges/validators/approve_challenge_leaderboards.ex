defmodule SegmentChallenge.Challenges.Challenges.Validators.ApproveChallengeLeaderboards do
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Repo

  @doc """
  Ensure that all stages in the challenge have been approved
  """
  def validate(_approval_message, context) do
    challenge_uuid = Map.get(context, :challenge_uuid)
    stages = challenge_uuid |> StagesInChallengeQuery.new() |> Repo.all()

    case Enum.all?(stages, &(&1.approved)) do
      true -> :ok
      _ -> {:error, "all stages must be approved"}
    end
  end
end
