defmodule SegmentChallenge.Challenges.AthleteChallengeParticipation do
  use Commanded.Event.Handler,
    name: "AthleteChallengeParticipation",
    start_from: :current

  alias SegmentChallenge.Challenges.Queries.Challenges.ChallengesEnteredByAthleteQuery
  alias SegmentChallenge.Challenges.Queries.Stages.StagesInChallengeQuery
  alias SegmentChallenge.Router
  alias SegmentChallenge.Stages.Stage.Commands.ConfigureAthleteGenderInStage
  alias SegmentChallenge.Events.AthleteGenderChanged
  alias SegmentChallenge.Repo

  def handle(%AthleteGenderChanged{athlete_uuid: athlete_uuid, gender: gender}, _metadata) do
    joined_challenges =
      athlete_uuid
      |> ChallengesEnteredByAthleteQuery.new(["upcoming", "active"])
      |> Repo.all()

    for challenge <- joined_challenges do
      stages =
        challenge.challenge_uuid
        |> StagesInChallengeQuery.new()
        |> Repo.all()

      for stage <- stages do
        :ok =
          Router.dispatch(%ConfigureAthleteGenderInStage{
            stage_uuid: stage.stage_uuid,
            athlete_uuid: athlete_uuid,
            gender: gender
          })
      end
    end

    :ok
  end
end
