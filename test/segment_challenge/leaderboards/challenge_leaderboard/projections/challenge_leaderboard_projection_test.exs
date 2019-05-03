defmodule SegmentChallenge.Projections.ChallengeLeaderboardProjectionTest do
  use SegmentChallenge.StorageCase

  import Ecto.Query, only: [from: 2]
  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.Enumerable
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase
  import SegmentChallenge.UseCases.ImportStageEffortUseCase
  import SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase

  alias SegmentChallenge.Events.ChallengeLeaderboardRanked
  alias SegmentChallenge.Projections.ChallengeLeaderboardEntryProjection
  alias SegmentChallenge.Projections.ChallengeLeaderboardProjection
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Wait

  @moduletag :integration
  @moduletag :projection

  describe "hosting a segment challenge" do
    setup [
      :create_challenge,
      :host_challenge
    ]

    test "should create a challenge leaderboard projection per challenge leaderboard", %{
      challenge_uuid: challenge_uuid
    } do
      Wait.until(fn ->
        leaderboards = leaderboard_query(challenge_uuid) |> Repo.all()

        assert length(leaderboards) == 6

        assert Enum.sort(pluck(leaderboards, :name)) == [
                 "GC",
                 "GC",
                 "KOM",
                 "QOM",
                 "Sprint",
                 "Sprint"
               ]

        assert Enum.sort(pluck(leaderboards, :description)) == [
                 "General classification",
                 "General classification",
                 "King of the mountains",
                 "Queen of the mountains",
                 "Sprint",
                 "Sprint"
               ]
      end)
    end
  end

  describe "segment stage ends, approve and finalise stage leaderboards" do
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

    test "should record leaderboard entry", %{athlete_uuid: athlete_uuid} do
      athlete_ranked =
        wait_for_event(ChallengeLeaderboardRanked, fn event ->
          Enum.any?(event.new_entries, fn entry ->
            entry.athlete_uuid == athlete_uuid
          end)
        end)

      challenge_leaderboard_uuid = athlete_ranked.data.challenge_leaderboard_uuid

      Wait.until(fn ->
        leaderboard_entries = entry_query(challenge_leaderboard_uuid, athlete_uuid) |> Repo.all()

        assert length(leaderboard_entries) > 0

        leaderboard_entry = hd(leaderboard_entries)
        assert leaderboard_entry.rank == 1
        assert leaderboard_entry.points == 15
      end)
    end
  end

  describe "hosting a distance challenge" do
    setup [
      :create_distance_challenge,
      :host_challenge
    ]

    test "should create a challenge leaderboard projection per challenge leaderboard", %{
      challenge_uuid: challenge_uuid
    } do
      Wait.until(fn ->
        leaderboards = leaderboard_query(challenge_uuid) |> Repo.all()

        assert length(leaderboards) == 2
        assert pluck(leaderboards, :name) == ["Overall", "Overall"]
        assert pluck(leaderboards, :description) == ["Overall", "Overall"]
      end)
    end
  end

  describe "distance stage ends, approve and finalise stage leaderboards" do
    setup [
      :create_distance_challenge,
      :host_challenge,
      :start_stage,
      :athlete_join_challenge,
      :import_distance_stage_efforts,
      :end_stage,
      :approve_stage_leaderboards
    ]

    test "should record leaderboard entry", %{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid} do
      athlete_ranked =
        wait_for_event(ChallengeLeaderboardRanked, fn event ->
          Enum.any?(event.new_entries, fn entry ->
            entry.athlete_uuid == athlete_uuid
          end)
        end)

      challenge_leaderboard_uuid = athlete_ranked.data.challenge_leaderboard_uuid

      Wait.until(fn ->
        leaderboard_entries = entry_query(challenge_leaderboard_uuid, athlete_uuid) |> Repo.all()

        assert length(leaderboard_entries) > 0

        leaderboard_entry = hd(leaderboard_entries)

        assert leaderboard_entry.rank == 1
        assert leaderboard_entry.points == 0
        assert leaderboard_entry.elapsed_time_in_seconds == 18363
        assert leaderboard_entry.moving_time_in_seconds == 16531
        assert leaderboard_entry.distance_in_metres == 145_129.8
        assert leaderboard_entry.elevation_gain_in_metres == 1421.0
        assert is_nil(leaderboard_entry.goals)
        assert leaderboard_entry.goal_progress == %{stage_uuid => nil}
      end)
    end
  end

  def leaderboard_query(challenge_uuid) do
    from(cl in ChallengeLeaderboardProjection,
      where: cl.challenge_uuid == ^challenge_uuid
    )
  end

  defp entry_query(challenge_leaderboard_uuid, athlete_uuid) do
    from(entry in ChallengeLeaderboardEntryProjection,
      where:
        entry.challenge_leaderboard_uuid == ^challenge_leaderboard_uuid and
          entry.athlete_uuid == ^athlete_uuid,
      order_by: [asc: entry.rank]
    )
  end
end
