defmodule SegmentChallenge.Projections.StageResultProjectionTest do
  use SegmentChallenge.StorageCase

  import Ecto.Query
  import SegmentChallenge.Enumerable
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase

  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.ChallengeStageProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.StageResultProjection
  alias SegmentChallenge.Leaderboards.StageLeaderboard.Results.StageResultEntryProjection
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Wait

  @moduletag :integration
  @moduletag :projection

  describe "hosting a challenge" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge
    ]

    test "should create stage result projection per stage and challenge leaderboard", %{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid
    } do
      Wait.until(fn ->
        leaderboards = query_stage_results(challenge_uuid, stage_uuid) |> Repo.all()

        assert length(leaderboards) == 6

        assert Enum.sort(pluck(leaderboards, :name)) == [
                 "GC",
                 "GC",
                 "KOM",
                 "QOM",
                 "Sprint",
                 "Sprint"
               ]

        assert Enum.sort(pluck(leaderboards, :gender)) == ["F", "F", "F", "M", "M", "M"]
      end)
    end
  end

  describe "stage created after hosting challenge" do
    setup [
      :create_challenge,
      :host_challenge,
      :create_stage
    ]

    test "should create stage result projection per stage and challenge leaderboard", %{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid
    } do
      Wait.until(fn ->
        leaderboards = query_stage_results(challenge_uuid, stage_uuid) |> Repo.all()

        assert length(leaderboards) == 6

        assert Enum.sort(pluck(leaderboards, :name)) == [
                 "GC",
                 "GC",
                 "KOM",
                 "QOM",
                 "Sprint",
                 "Sprint"
               ]

        assert Enum.sort(pluck(leaderboards, :gender)) == ["F", "F", "F", "M", "M", "M"]
      end)
    end
  end

  describe "stage ends, finalise stage leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage
    ]

    test "should record leaderboard entry", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      Wait.until(fn ->
        entries = query_stage_result_entries(stage_uuid, athlete_uuid) |> Repo.all()

        assert length(entries) > 0

        entry = hd(Enum.sort_by(entries, &(-&1.points)))
        assert entry.rank == 1
        assert is_nil(entry.rank_change)
        assert entry.points == 15
        assert entry.points_gained == 15
      end)
    end
  end

  describe "stage ends, approve and finalise stage leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should record leaderboard entry", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      Wait.until(fn ->
        entries = query_stage_result_entries(stage_uuid, athlete_uuid) |> Repo.all()

        assert length(entries) > 0

        entry = hd(Enum.sort_by(entries, &(-&1.points)))
        assert entry.rank == 1
        assert is_nil(entry.rank_change)
        assert entry.points == 15
        assert entry.points_gained == 15
      end)
    end
  end

  describe "stage 2 ends, approve and finalise stage leaderboards" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :athlete_join_challenge,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards,
      :create_second_stage,
      :start_stage,
      :wait_for_competitor_to_join_stage,
      :import_segment_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should record leaderboard entry", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      Wait.until(fn ->
        entries = query_stage_result_entries(stage_uuid, athlete_uuid) |> Repo.all()

        assert length(entries) > 0

        entry = hd(Enum.sort_by(entries, &(-&1.points)))
        assert entry.rank == 1
        assert entry.rank_change == 0
        assert entry.points == 30
        assert entry.points_gained == 15
      end)
    end
  end

  describe "stage deleted" do
    setup [
      :create_challenge,
      :create_stage,
      :delete_stage
    ]

    test "should remove stage results", %{challenge_uuid: challenge_uuid} do
      Wait.until(fn ->
        assert query_challenge_stages(challenge_uuid) |> Repo.all() == []
      end)
    end
  end

  defp query_stage_results(challenge_uuid, stage_uuid) do
    from(sr in StageResultProjection,
      where:
        sr.challenge_uuid == ^challenge_uuid and sr.stage_uuid == ^stage_uuid and
          not is_nil(sr.challenge_leaderboard_uuid)
    )
  end

  defp query_stage_result_entries(stage_uuid, athlete_uuid) do
    from(e in StageResultEntryProjection,
      where: e.stage_uuid == ^stage_uuid and e.athlete_uuid == ^athlete_uuid
    )
  end

  defp query_challenge_stages(challenge_uuid) do
    from(cs in ChallengeStageProjection,
      where: cs.challenge_uuid == ^challenge_uuid
    )
  end
end
