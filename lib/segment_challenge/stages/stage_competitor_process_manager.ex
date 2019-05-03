defmodule SegmentChallenge.Stages.StageCompetitorProcessManager do
  @moduledoc """
  Track atheletes who are competing in the stages of a challenge.
  """

  use Commanded.ProcessManagers.ProcessManager,
    name: "StageCompetitorProcessManager",
    router: SegmentChallenge.Router

  @derive Jason.Encoder
  defstruct [
    :active_stage,
    :challenge_uuid,
    challenge_type: "segment",
    competitors: [],
    stages: []
  ]

  defmodule ChallengeStage do
    @derive Jason.Encoder
    defstruct [:stage_uuid, stage_type: "segment"]
  end

  defmodule Competitor do
    @derive Jason.Encoder
    defstruct [
      :athlete_uuid,
      :firstname,
      :lastname,
      :gender
    ]
  end

  alias SegmentChallenge.Stages.Stage.Commands.{
    IncludeCompetitorsInStage,
    RemoveCompetitorFromStage
  }

  alias SegmentChallenge.Events.{
    AthleteGenderAmendedInStage,
    ChallengeCreated,
    ChallengeEnded,
    CompetitorJoinedChallenge,
    CompetitorsJoinedChallenge,
    CompetitorLeftChallenge,
    CompetitorExcludedFromChallenge,
    StageCreated,
    StageDeleted,
    StageEnded,
    StageStarted
  }

  alias SegmentChallenge.Stages.StageCompetitorProcessManager

  alias SegmentChallenge.Stages.StageCompetitorProcessManager.{
    ChallengeStage,
    Competitor
  }

  def interested?(%ChallengeCreated{challenge_uuid: challenge_uuid}), do: {:start, challenge_uuid}

  def interested?(%CompetitorJoinedChallenge{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%CompetitorsJoinedChallenge{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%CompetitorLeftChallenge{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%CompetitorExcludedFromChallenge{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%StageCreated{challenge_uuid: challenge_uuid}), do: {:continue, challenge_uuid}
  def interested?(%StageDeleted{challenge_uuid: challenge_uuid}), do: {:continue, challenge_uuid}
  def interested?(%StageStarted{challenge_uuid: challenge_uuid}), do: {:continue, challenge_uuid}
  def interested?(%StageEnded{challenge_uuid: challenge_uuid}), do: {:continue, challenge_uuid}

  def interested?(%AthleteGenderAmendedInStage{challenge_uuid: challenge_uuid}),
    do: {:continue, challenge_uuid}

  def interested?(%ChallengeEnded{challenge_uuid: challenge_uuid}), do: {:stop, challenge_uuid}

  @doc """
  Include competitor in active stage
  """
  def handle(%StageCompetitorProcessManager{} = pm, %CompetitorJoinedChallenge{} = event) do
    %StageCompetitorProcessManager{active_stage: active_stage} = pm

    case active_stage do
      %ChallengeStage{stage_uuid: stage_uuid} ->
        include_competitors_in_stage(stage_uuid, [event])

      nil ->
        []
    end
  end

  @doc """
  Include competitors in active stage
  """
  def handle(%StageCompetitorProcessManager{} = pm, %CompetitorsJoinedChallenge{} = event) do
    %StageCompetitorProcessManager{active_stage: active_stage} = pm
    %CompetitorsJoinedChallenge{competitors: competitors} = event

    case active_stage do
      %ChallengeStage{stage_uuid: stage_uuid} ->
        include_competitors_in_stage(stage_uuid, competitors)

      nil ->
        []
    end
  end

  @doc """
  Remove competitor from active stage.
  """
  def handle(%StageCompetitorProcessManager{} = pm, %CompetitorLeftChallenge{} = event) do
    %CompetitorLeftChallenge{athlete_uuid: athlete_uuid, left_at: left_at} = event

    remove_competitor_from_active_stage(pm, athlete_uuid, left_at)
  end

  @doc """
  Remove competitor from active stage
  """
  def handle(%StageCompetitorProcessManager{} = pm, %CompetitorExcludedFromChallenge{} = event) do
    %CompetitorExcludedFromChallenge{athlete_uuid: athlete_uuid, excluded_at: excluded_at} = event

    remove_competitor_from_active_stage(pm, athlete_uuid, excluded_at)
  end

  def handle(%StageCompetitorProcessManager{}, %AthleteGenderAmendedInStage{}), do: []

  @doc """
  Include competitors from the challenge into the stage once it has started
  """
  def handle(%StageCompetitorProcessManager{} = pm, %StageStarted{} = event) do
    %StageCompetitorProcessManager{competitors: competitors} = pm
    %StageStarted{stage_uuid: stage_uuid} = event

    case find_stage(pm, stage_uuid) do
      %ChallengeStage{} ->
        include_competitors_in_stage(stage_uuid, competitors)

      nil ->
        []
    end
  end

  def handle(%StageCompetitorProcessManager{}, _event), do: []

  ## State mutators

  def apply(%StageCompetitorProcessManager{} = pm, %ChallengeCreated{} = event) do
    %ChallengeCreated{challenge_uuid: challenge_uuid} = event

    %StageCompetitorProcessManager{pm | challenge_uuid: challenge_uuid}
  end

  def apply(
        %StageCompetitorProcessManager{competitors: competitors} = process_manager,
        %CompetitorJoinedChallenge{} = joined
      ) do
    competitor = struct(Competitor, Map.from_struct(joined))

    %StageCompetitorProcessManager{process_manager | competitors: [competitor | competitors]}
  end

  def apply(
        %StageCompetitorProcessManager{competitors: competitors} = process_manager,
        %CompetitorsJoinedChallenge{competitors: joined}
      ) do
    %StageCompetitorProcessManager{
      process_manager
      | competitors: competitors ++ Enum.map(joined, &struct(Competitor, Map.from_struct(&1)))
    }
  end

  def apply(
        %StageCompetitorProcessManager{competitors: competitors} = process_manager,
        %CompetitorLeftChallenge{athlete_uuid: athlete_uuid}
      ) do
    %StageCompetitorProcessManager{
      process_manager
      | competitors:
          Enum.reject(competitors, fn competitor -> competitor.athlete_uuid == athlete_uuid end)
    }
  end

  def apply(
        %StageCompetitorProcessManager{competitors: competitors} = process_manager,
        %CompetitorExcludedFromChallenge{athlete_uuid: athlete_uuid}
      ) do
    %StageCompetitorProcessManager{
      process_manager
      | competitors:
          Enum.reject(competitors, fn competitor -> competitor.athlete_uuid == athlete_uuid end)
    }
  end

  def apply(%StageCompetitorProcessManager{} = pm, %StageCreated{} = event) do
    %StageCompetitorProcessManager{stages: stages} = pm
    %StageCreated{stage_uuid: stage_uuid, stage_type: stage_type} = event

    stage = %ChallengeStage{stage_uuid: stage_uuid, stage_type: stage_type}

    %StageCompetitorProcessManager{pm | stages: stages ++ [stage]}
  end

  def apply(%StageCompetitorProcessManager{stages: stages} = process_manager, %StageDeleted{
        stage_uuid: stage_uuid
      }) do
    %StageCompetitorProcessManager{
      process_manager
      | stages: Enum.reject(stages, fn stage -> stage.stage_uuid == stage_uuid end)
    }
  end

  def apply(%StageCompetitorProcessManager{} = pm, %StageStarted{} = event) do
    %StageStarted{stage_uuid: stage_uuid} = event

    active_stage = find_stage(pm, stage_uuid)

    %StageCompetitorProcessManager{pm | active_stage: active_stage}
  end

  def apply(%StageCompetitorProcessManager{} = pm, %StageEnded{} = ended) do
    %StageCompetitorProcessManager{active_stage: active_stage} = pm
    %StageEnded{stage_uuid: stage_uuid} = ended

    case active_stage do
      %ChallengeStage{stage_uuid: ^stage_uuid} ->
        %StageCompetitorProcessManager{pm | active_stage: nil}

      _active_stage ->
        pm
    end
  end

  def apply(
        %StageCompetitorProcessManager{competitors: competitors} = process_manager,
        %AthleteGenderAmendedInStage{athlete_uuid: athlete_uuid, gender: gender}
      ) do
    competitors =
      competitors
      |> Enum.reduce([], fn competitor, competitors ->
        case competitor.athlete_uuid do
          ^athlete_uuid -> [%Competitor{competitor | gender: gender} | competitors]
          _ -> [competitor | competitors]
        end
      end)
      |> Enum.reverse()

    %StageCompetitorProcessManager{process_manager | competitors: competitors}
  end

  # Private helpers

  defp find_stage(%StageCompetitorProcessManager{} = pm, stage_uuid) do
    %StageCompetitorProcessManager{stages: stages} = pm

    Enum.find(stages, fn
      %ChallengeStage{stage_uuid: ^stage_uuid} -> true
      %ChallengeStage{} -> false
    end)
  end

  defp include_competitors_in_stage(stage_uuid, competitors) do
    competitors =
      Enum.map(
        competitors,
        &struct(IncludeCompetitorsInStage.Competitor, Map.from_struct(&1))
      )

    %IncludeCompetitorsInStage{stage_uuid: stage_uuid, competitors: competitors}
  end

  defp remove_competitor_from_active_stage(
         %StageCompetitorProcessManager{} = pm,
         athlete_uuid,
         removed_at
       ) do
    %StageCompetitorProcessManager{active_stage: active_stage} = pm

    case active_stage do
      %ChallengeStage{stage_uuid: stage_uuid} ->
        %RemoveCompetitorFromStage{
          stage_uuid: stage_uuid,
          athlete_uuid: athlete_uuid,
          removed_at: removed_at
        }

      nil ->
        []
    end
  end
end
