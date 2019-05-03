defmodule SegmentChallenge.Leaderboards.RemoveChallengeLeaderboardTest do
  use SegmentChallenge.StorageCase

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.UseCases.CreateChallengeUseCase
  import SegmentChallenge.UseCases.CreateStageUseCase

  alias SegmentChallenge.Commands.RemoveChallengeLeaderboard
  alias SegmentChallenge.Events.ChallengeLeaderboardRemoved
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Router
  alias SegmentChallenge.Wait
  alias SegmentChallenge.Projections.ChallengeLeaderboardProjection
  alias SegmentChallenge.Challenges.Queries.Leaderboards.ChallengeLeaderboardQuery

  @moduletag :integration

  describe "remove challenge leaderboard" do
    setup [
      :create_challenge,
      :create_stage,
      :host_challenge,
      :remove_challenge_leaderboard
    ]

    test "should remove leaderboard projection", %{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid
    } do
      assert Repo.get(ChallengeLeaderboardProjection, challenge_leaderboard_uuid) == nil
    end
  end

  defp remove_challenge_leaderboard(context) do
    %{challenge_uuid: challenge_uuid} = context

    challenge_leaderboard_uuid =
      Wait.until(fn ->
        challenge_leaderboard =
          challenge_uuid
          |> ChallengeLeaderboardQuery.new()
          |> Repo.all()
          |> Enum.find(fn leaderboard -> leaderboard.name == "GC" && leaderboard.gender == "M" end)

        refute is_nil(challenge_leaderboard)

        challenge_leaderboard.challenge_leaderboard_uuid
      end)

    :ok =
      Router.dispatch(%RemoveChallengeLeaderboard{
        challenge_leaderboard_uuid: challenge_leaderboard_uuid
      })

    wait_for_event(ChallengeLeaderboardRemoved, fn event ->
      event.challenge_leaderboard_uuid == challenge_leaderboard_uuid
    end)

    [challenge_leaderboard_uuid: challenge_leaderboard_uuid]
  end
end
