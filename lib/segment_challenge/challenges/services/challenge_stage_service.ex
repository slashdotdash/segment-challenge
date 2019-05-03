defmodule SegmentChallenge.Challenges.ChallengeStageService do
  use Timex

  defmodule NextStage do
    defstruct [
      :stage_number,
      :start_date,
      :start_date_local,
      :end_date,
      :end_date_local
    ]
  end

  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Repo

  def next_stage(challenge_uuid) when is_bitstring(challenge_uuid) do
    challenge = Repo.get!(ChallengeProjection, challenge_uuid)

    next_stage(challenge)
  end

  def next_stage(%ChallengeProjection{challenge_uuid: challenge_uuid} = challenge) do
    last_stage = get_last_stage(challenge_uuid)

    build_next_stage(challenge, last_stage)
  end

  def challenge_stages(challenge_uuid) do
    challenge_uuid |> StagesInChallengeQuery.new() |> Repo.all()
  end

  defp get_last_stage(challenge_uuid) do
    challenge_uuid |> challenge_stages() |> List.last()
  end

  defp build_next_stage(challenge, last_stage) do
    case last_stage do
      nil ->
        %NextStage{
          stage_number: 1,
          start_date: challenge.start_date,
          start_date_local: challenge.start_date_local,
          end_date: challenge.end_date,
          end_date_local: challenge.end_date_local
        }

      stage ->
        start_date = Timex.add(stage.end_date, Duration.from_seconds(1))
        start_date_local = Timex.add(stage.end_date_local, Duration.from_seconds(1))

        %NextStage{
          stage_number: stage.stage_number + 1,
          start_date: start_date,
          start_date_local: start_date_local,
          end_date: challenge.end_date,
          end_date_local: challenge.end_date_local
        }
    end
  end
end
