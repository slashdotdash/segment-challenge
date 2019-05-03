defmodule SegmentChallenge.Authorisation.Policies.StagePolicy do
  alias SegmentChallenge.Authorisation.User

  alias SegmentChallenge.Stages.Stage.Commands.{
    ApproveStageLeaderboards,
    ConfigureAthleteGenderInStage,
    CreateActivityStage,
    CreateSegmentStage,
    DeleteStage,
    FlagStageEffort,
    PublishStageResults,
    RevealStage,
    SetStageDescription
  }

  alias SegmentChallenge.Projections.{
    ChallengeProjection,
    StageProjection
  }

  alias SegmentChallenge.Repo

  def commands(%User{} = user, %StageProjection{} = stage, %ChallengeProjection{} = challenge) do
    user
    |> stage_commands(stage, challenge)
    |> Enum.filter(fn {_name, command} -> can?(user, :dispatch, command, stage, challenge) end)
  end

  def command(
        name,
        %User{} = user,
        %StageProjection{} = stage,
        %ChallengeProjection{} = challenge
      ) do
    user
    |> stage_commands(stage, challenge)
    |> Enum.find(fn
      {^name, command} -> can?(user, :dispatch, command, stage, challenge)
      _ -> false
    end)
  end

  def can?(
        %User{} = user,
        :dispatch,
        %{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid} = command
      ) do
    stage = Repo.get(StageProjection, stage_uuid)
    challenge = Repo.get(ChallengeProjection, challenge_uuid)

    can?(user, :dispatch, command, stage, challenge)
  end

  def can?(%User{} = user, :dispatch, %{stage_uuid: stage_uuid} = command) do
    %StageProjection{challenge_uuid: challenge_uuid} =
      stage = Repo.get(StageProjection, stage_uuid)

    challenge = Repo.get(ChallengeProjection, challenge_uuid)

    can?(user, :dispatch, command, stage, challenge)
  end

  def can?(_user, _action, _command), do: false

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %ConfigureAthleteGenderInStage{athlete_uuid: athlete_uuid, stage_uuid: stage_uuid},
        %StageProjection{stage_uuid: stage_uuid},
        %ChallengeProjection{}
      ),
      do: true

  @doc """
  Allow the athlete who created the stage to flag stage efforts
  """
  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %FlagStageEffort{flagged_by_athlete_uuid: athlete_uuid, stage_uuid: stage_uuid},
        %StageProjection{
          stage_uuid: stage_uuid,
          created_by_athlete_uuid: athlete_uuid,
          approved: false
        },
        %ChallengeProjection{}
      ),
      do: true

  @doc """
  Allow the athlete who created the challenge to create a stage in it
  """
  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %CreateActivityStage{
          created_by_athlete_uuid: athlete_uuid,
          challenge_uuid: challenge_uuid
        },
        nil,
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid
        }
      ),
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %CreateSegmentStage{
          created_by_athlete_uuid: athlete_uuid,
          challenge_uuid: challenge_uuid
        },
        nil,
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid
        }
      ),
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %ApproveStageLeaderboards{
          stage_uuid: stage_uuid,
          approved_by_athlete_uuid: athlete_uuid,
          approved_by_club_uuid: club_uuid
        },
        %StageProjection{
          stage_uuid: stage_uuid,
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          status: "past",
          approved: false
        },
        %ChallengeProjection{challenge_uuid: challenge_uuid, hosted_by_club_uuid: club_uuid}
      ),
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %RevealStage{stage_uuid: stage_uuid},
        %StageProjection{
          stage_uuid: stage_uuid,
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          visible: false
        },
        %ChallengeProjection{challenge_uuid: challenge_uuid, status: challenge_status}
      )
      when challenge_status in ["upcoming", "active"],
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %DeleteStage{stage_uuid: stage_uuid, deleted_by_athlete_uuid: athlete_uuid},
        %StageProjection{
          stage_uuid: stage_uuid,
          stage_type: stage_type,
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          status: stage_status
        },
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid
        }
      )
      when stage_type in ["mountain", "rolling", "flat"] and
             stage_status in ["pending", "upcoming"],
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %SetStageDescription{stage_uuid: stage_uuid, updated_by_athlete_uuid: athlete_uuid},
        %StageProjection{
          stage_uuid: stage_uuid,
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid
        },
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid
        }
      ),
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %PublishStageResults{stage_uuid: stage_uuid, published_by_athlete_uuid: athlete_uuid},
        %StageProjection{
          stage_uuid: stage_uuid,
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          status: "past"
        },
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid
        }
      ),
      do: true

  def can?(_user, _action, _command, _stage, _challenge), do: false

  defp stage_commands(
         %User{} = user,
         %StageProjection{} = stage,
         %ChallengeProjection{} = challenge
       ) do
    %User{athlete_uuid: athlete_uuid} = user
    %StageProjection{stage_uuid: stage_uuid} = stage

    %ChallengeProjection{challenge_uuid: challenge_uuid, hosted_by_club_uuid: club_uuid} =
      challenge

    [
      approve_stage: %ApproveStageLeaderboards{
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        approved_by_athlete_uuid: athlete_uuid,
        approved_by_club_uuid: club_uuid
      },
      delete_stage: %DeleteStage{
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        deleted_by_athlete_uuid: athlete_uuid
      },
      publish_stage_results: %PublishStageResults{
        stage_uuid: stage_uuid,
        published_by_athlete_uuid: athlete_uuid,
        published_by_club_uuid: club_uuid
      },
      reveal_stage: %RevealStage{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid},
      set_stage_description: %SetStageDescription{
        challenge_uuid: challenge_uuid,
        stage_uuid: stage_uuid,
        updated_by_athlete_uuid: athlete_uuid
      }
    ]
  end
end
