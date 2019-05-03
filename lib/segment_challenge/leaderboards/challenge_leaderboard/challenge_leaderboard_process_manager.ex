defmodule SegmentChallenge.Leaderboards.ChallengeLeaderboardProcessManager do
  @moduledoc """
  Create leaderboards for a hosted challenge.
  """

  use Commanded.ProcessManagers.ProcessManager,
    name: "ChallengeLeaderboardProcessManager",
    router: SegmentChallenge.Router

  use SegmentChallenge.Challenges.Challenge.Aliases
  use SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases
  use SegmentChallenge.Leaderboards.StageLeaderboard.Aliases

  alias SegmentChallenge.Leaderboards.ChallengeLeaderboardProcessManager
  alias ChallengeLeaderboardProcessManager.Leaderboard

  @derive Jason.Encoder
  defstruct [:challenge_uuid, leaderboards: [], stage_uuids: []]

  defmodule Leaderboard do
    @derive Jason.Encoder
    defstruct [:challenge_leaderboard_uuid, :gender]
  end

  def interested?(%ChallengeHosted{challenge_uuid: challenge_uuid}), do: {:start, challenge_uuid}

  def interested?(%ChallengeLeaderboardRequested{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeLeaderboardCreated{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeLeaderboardRemoved{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeStagesConfigured{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%StageRemovedFromChallenge{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%CompetitorParticipationInChallengeAllowed{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%CompetitorParticipationInChallengeLimited{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%StageLeaderboardAdjusted{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%StageLeaderboardFinalised{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeLeaderboardsApproved{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  @doc """
  Create a requested leaderboard for a hosted challenge
  """
  def handle(%ChallengeLeaderboardProcessManager{}, %ChallengeLeaderboardRequested{} = event) do
    %ChallengeLeaderboardRequested{
      challenge_uuid: challenge_uuid,
      name: name,
      description: description,
      gender: gender,
      points: points,
      challenge_type: challenge_type,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal?: has_goal
    } = event

    %CreateChallengeLeaderboard{
      challenge_leaderboard_uuid: UUID.uuid4(),
      challenge_uuid: challenge_uuid,
      name: name,
      description: description,
      gender: gender,
      points: points,
      challenge_type: challenge_type,
      rank_by: rank_by,
      rank_order: rank_order,
      has_goal: has_goal
    }
  end

  @doc """
  Submit finalised stage leaderboard to challenge lederboards with matching gender
  """
  def handle(%ChallengeLeaderboardProcessManager{}, %StageLeaderboardFinalised{entries: []}),
    do: []

  def handle(%ChallengeLeaderboardProcessManager{} = pm, %StageLeaderboardFinalised{} = event) do
    %ChallengeLeaderboardProcessManager{leaderboards: leaderboards, stage_uuids: stage_uuids} = pm

    %StageLeaderboardFinalised{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      gender: gender,
      entries: entries
    } = event

    leaderboards
    |> Enum.filter(fn leaderboard -> leaderboard.gender == gender end)
    |> Enum.map(fn leaderboard ->
      %AssignPointsFromStageLeaderboard{
        challenge_leaderboard_uuid: leaderboard.challenge_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        challenge_stage_uuids: stage_uuids,
        stage_uuid: stage_uuid,
        stage_type: stage_type,
        points_adjustment: points_adjustment,
        entries: entries
      }
    end)
  end

  def handle(%ChallengeLeaderboardProcessManager{}, %StageLeaderboardAdjusted{
        adjusted_entries: []
      }),
      do: []

  def handle(%ChallengeLeaderboardProcessManager{} = pm, %StageLeaderboardAdjusted{} = event) do
    %ChallengeLeaderboardProcessManager{leaderboards: leaderboards, stage_uuids: stage_uuids} = pm

    %StageLeaderboardAdjusted{
      challenge_uuid: challenge_uuid,
      stage_uuid: stage_uuid,
      stage_type: stage_type,
      points_adjustment: points_adjustment,
      gender: gender,
      previous_entries: previous_entries,
      adjusted_entries: adjusted_entries
    } = event

    leaderboards
    |> Enum.filter(fn leaderboard -> leaderboard.gender == gender end)
    |> Enum.map(fn leaderboard ->
      %AdjustPointsFromStageLeaderboard{
        challenge_leaderboard_uuid: leaderboard.challenge_leaderboard_uuid,
        challenge_uuid: challenge_uuid,
        challenge_stage_uuids: stage_uuids,
        stage_uuid: stage_uuid,
        stage_type: stage_type,
        points_adjustment: points_adjustment,
        previous_entries: previous_entries,
        adjusted_entries: adjusted_entries
      }
    end)
  end

  def handle(
        %ChallengeLeaderboardProcessManager{} = pm,
        %CompetitorParticipationInChallengeAllowed{} = event
      ) do
    %ChallengeLeaderboardProcessManager{leaderboards: leaderboards} = pm
    %CompetitorParticipationInChallengeAllowed{athlete_uuid: athlete_uuid} = event

    Enum.map(leaderboards, fn leaderboard ->
      %AllowCompetitorPointScoringInChallengeLeaderboard{
        challenge_leaderboard_uuid: leaderboard.challenge_leaderboard_uuid,
        athlete_uuid: athlete_uuid
      }
    end)
  end

  def handle(
        %ChallengeLeaderboardProcessManager{} = pm,
        %CompetitorParticipationInChallengeLimited{} = event
      ) do
    %ChallengeLeaderboardProcessManager{leaderboards: leaderboards} = pm
    %CompetitorParticipationInChallengeLimited{athlete_uuid: athlete_uuid, reason: reason} = event

    Enum.map(leaderboards, fn leaderboard ->
      %LimitCompetitorPointScoringInChallengeLeaderboard{
        challenge_leaderboard_uuid: leaderboard.challenge_leaderboard_uuid,
        athlete_uuid: athlete_uuid,
        reason: reason
      }
    end)
  end

  def handle(%ChallengeLeaderboardProcessManager{} = pm, %ChallengeLeaderboardsApproved{}) do
    %ChallengeLeaderboardProcessManager{leaderboards: leaderboards} = pm

    Enum.map(leaderboards, fn leaderboard ->
      %FinaliseChallengeLeaderboard{
        challenge_leaderboard_uuid: leaderboard.challenge_leaderboard_uuid
      }
    end)
  end

  ## State mutators

  def apply(%ChallengeLeaderboardProcessManager{} = pm, %ChallengeHosted{} = event) do
    %ChallengeLeaderboardProcessManager{} = pm
    %ChallengeHosted{challenge_uuid: challenge_uuid} = event

    %ChallengeLeaderboardProcessManager{pm | challenge_uuid: challenge_uuid}
  end

  def apply(%ChallengeLeaderboardProcessManager{} = pm, %ChallengeStagesConfigured{} = event) do
    %ChallengeStagesConfigured{stage_uuids: stage_uuids} = event

    %ChallengeLeaderboardProcessManager{pm | stage_uuids: stage_uuids}
  end

  def apply(%ChallengeLeaderboardProcessManager{} = pm, %StageRemovedFromChallenge{} = event) do
    %ChallengeLeaderboardProcessManager{stage_uuids: stage_uuids} = pm
    %StageRemovedFromChallenge{stage_uuid: stage_uuid} = event

    %ChallengeLeaderboardProcessManager{pm | stage_uuids: stage_uuids -- [stage_uuid]}
  end

  def apply(%ChallengeLeaderboardProcessManager{} = pm, %ChallengeLeaderboardCreated{} = event) do
    %ChallengeLeaderboardProcessManager{leaderboards: leaderboards} = pm

    %ChallengeLeaderboardCreated{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      gender: gender
    } = event

    leaderboard = %Leaderboard{
      challenge_leaderboard_uuid: challenge_leaderboard_uuid,
      gender: gender
    }

    %ChallengeLeaderboardProcessManager{pm | leaderboards: leaderboards ++ [leaderboard]}
  end

  def apply(%ChallengeLeaderboardProcessManager{} = pm, %ChallengeLeaderboardRemoved{} = event) do
    %ChallengeLeaderboardProcessManager{leaderboards: leaderboards} = pm
    %ChallengeLeaderboardRemoved{challenge_leaderboard_uuid: challenge_leaderboard_uuid} = event

    %ChallengeLeaderboardProcessManager{
      pm
      | leaderboards:
          Enum.reject(leaderboards, fn leaderboard ->
            leaderboard.challenge_leaderboard_uuid == challenge_leaderboard_uuid
          end)
    }
  end
end
