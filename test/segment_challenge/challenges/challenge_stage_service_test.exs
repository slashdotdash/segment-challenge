defmodule SegmentChallenge.Challenges.ChallengeStageServiceTest do
  use SegmentChallenge.StorageCase

  import SegmentChallenge.UseCases.CreateChallengeUseCase, only: [create_challenge: 1]
  import SegmentChallenge.UseCases.CreateStageUseCase, only: [create_stage: 1]

  alias SegmentChallenge.Challenges.ChallengeStageService
  alias SegmentChallenge.Challenges.ChallengeStageService.NextStage
  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Repo

  describe "next stage when no stages exist" do
    setup [:create_challenge]

    @tag :integration
    test "should return stage 1 with challenge start and end dates", context do
      challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

      assert ChallengeStageService.next_stage(challenge) == %NextStage{
               stage_number: 1,
               start_date: ~N[2016-01-01 00:00:00],
               start_date_local: ~N[2016-01-01 00:00:00],
               end_date: ~N[2016-10-31 23:59:59],
               end_date_local: ~N[2016-10-31 23:59:59]
             }
    end
  end

  describe "next stage when a stages exists" do
    setup [:create_challenge, :create_stage]

    @tag :integration
    test "should return stage 2 with stage and challenge end dates", context do
      challenge = Repo.get(ChallengeProjection, context[:challenge_uuid])

      assert ChallengeStageService.next_stage(challenge) == %NextStage{
               stage_number: 2,
               start_date: ~N[2016-02-01 00:00:00],
               start_date_local: ~N[2016-02-01 00:00:00],
               end_date: ~N[2016-10-31 23:59:59],
               end_date_local: ~N[2016-10-31 23:59:59]
             }
    end
  end
end
