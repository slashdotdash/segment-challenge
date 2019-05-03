defmodule SegmentChallenge.UseCases.ApproveChallengeLeaderboardsUseCase do
  import Commanded.Assertions.EventAssertions

  alias SegmentChallenge.Commands.ApproveChallengeLeaderboards
  alias SegmentChallenge.Events.ChallengeLeaderboardsApproved
  alias SegmentChallenge.Router

  def approve_challenge_leaderboards(context) do
    :ok =
      Router.dispatch(%ApproveChallengeLeaderboards{
        challenge_uuid: context[:challenge_uuid],
        approved_by_athlete_uuid: context[:athlete_uuid],
        approved_by_club_uuid: context[:club_uuid],
        approval_message: "Congratulations to Ben for winning the competition."
      })

    wait_for_event(ChallengeLeaderboardsApproved, fn event ->
      event.challenge_uuid == context[:challenge_uuid]
    end)

    context
  end
end
