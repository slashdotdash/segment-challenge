defmodule SegmentChallenge.UseCases.ApproveStageLeaderboardsUseCase do
  import Commanded.Assertions.EventAssertions

  alias SegmentChallenge.Stages.Stage.Commands.ApproveStageLeaderboards
  alias SegmentChallenge.Events.StageLeaderboardsApproved
  alias SegmentChallenge.Router

  def approve_stage_leaderboards(context) do
    :ok =
      Router.dispatch(%ApproveStageLeaderboards{
        challenge_uuid: context[:challenge_uuid],
        stage_uuid: context[:stage_uuid],
        approved_by_athlete_uuid: context[:athlete_uuid],
        approved_by_club_uuid: context[:club_uuid],
        approval_message: "Congratulations to Ben for winning the stage."
      })

    wait_for_event(StageLeaderboardsApproved, fn event ->
      event.stage_uuid == context[:stage_uuid]
    end)

    context
  end
end
