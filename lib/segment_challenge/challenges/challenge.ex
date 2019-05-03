defmodule SegmentChallenge.Challenges.Challenge do
  @moduledoc """
  Challenges are multi-stage competitions, hosted by a club.

  Challenges can be one of the following types:

    - "segment" - fastest time set over a Strava segment
    - "distance" - total distance (e.g. "October cycling distance challenge")
    - "duration" - total duration
    - "elevation" - total climbing
    - "race" - fastest time for a set distance (e.g. "Virtual 5k")

  """

  defstruct [
    :challenge_uuid,
    :challenge_type,
    :name,
    :description,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :hosted_by_club_uuid,
    :hosted_by_club_name,
    :created_by_athlete_uuid,
    :results_message,
    :goal,
    :goal_units,
    :goal_recurrence,
    :url_slug,
    :status,
    has_goal?: false,
    private: false,
    allow_private_activities?: false,
    accumulate_activities?: false,
    included_activity_types: [],
    stages: [],
    competitors: MapSet.new(),
    excluded_competitors: MapSet.new(),
    limited_competitors: MapSet.new(),
    leaderboards: []
  ]

  defmodule Stage do
    @derive Jason.Encoder
    defstruct [
      :stage_uuid,
      :stage_number,
      :name,
      :start_date,
      :start_date_local,
      :end_date,
      :end_date_local,
      :available
    ]
  end

  defmodule Leaderboard do
    @derive Jason.Encoder
    defstruct [
      :name,
      :description,
      :gender
    ]
  end

  use SegmentChallenge.Challenges.Challenge.Aliases
  use SegmentChallenge.Challenges.ActivityChallenge
  use SegmentChallenge.Challenges.SegmentChallenge
  use SegmentChallenge.Challenges.VirtualRace

  alias Commanded.Aggregate.Multi
  alias SegmentChallenge.Challenges.Challenge
  alias SegmentChallenge.Challenges.Challenge.Leaderboard
  alias SegmentChallenge.Challenges.Challenge.Stage

  @doc """
  Create a new challenge.
  """
  def execute(%Challenge{status: nil} = challenge, %CreateChallenge{} = command) do
    %CreateChallenge{stages: stages} = command

    challenge
    |> Multi.new()
    |> Multi.execute(fn _challenge -> create_challenge(command) end)
    |> Multi.execute(&configure_goal(&1, command))
    |> Multi.execute(&request_stages(&1, stages))
  end

  def execute(%Challenge{}, %CreateChallenge{}), do: {:error, :challenge_already_created}

  @doc """
  Rename an existing challenge.
  """
  def execute(%Challenge{name: name}, %RenameChallenge{name: name}), do: []

  def execute(%Challenge{status: :cancelled}, %RenameChallenge{}),
    do: {:error, :challenge_cannot_be_renamed}

  def execute(%Challenge{status: :ended}, %RenameChallenge{}),
    do: {:error, :challenge_cannot_be_renamed}

  def execute(%Challenge{} = challenge, %RenameChallenge{} = command) do
    %Challenge{challenge_uuid: challenge_uuid, status: state, url_slug: url_slug} = challenge

    %RenameChallenge{
      name: name,
      renamed_by_athlete_uuid: renamed_by_athlete_uuid,
      slugger: slugger
    } = command

    {:ok, url_slug} =
      case state do
        :created ->
          # generate a new URL slug from new name for created challenges
          slugger.("challenge", challenge_uuid, name)

        _ ->
          # use the existing URL slug once the challenge has been hosted
          {:ok, url_slug}
      end

    %ChallengeRenamed{
      challenge_uuid: challenge_uuid,
      name: name,
      url_slug: url_slug,
      renamed_by_athlete_uuid: renamed_by_athlete_uuid
    }
  end

  @doc """
  Competitor join challenge.
  """
  def execute(%Challenge{} = challenge, %JoinChallenge{} = join) do
    %JoinChallenge{athlete_uuid: athlete_uuid} = join

    with false <- is_challenge_competitor?(challenge, athlete_uuid),
         false <- is_excluded_competitor?(challenge, athlete_uuid) do
      struct(CompetitorJoinedChallenge, Map.from_struct(join))
    else
      _ -> []
    end
  end

  @doc """
  Competitor leave challenge.
  """
  def execute(%Challenge{} = challenge, %LeaveChallenge{} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge
    %LeaveChallenge{athlete_uuid: athlete_uuid} = command

    case is_challenge_competitor?(challenge, athlete_uuid) do
      true ->
        %CompetitorLeftChallenge{
          challenge_uuid: challenge_uuid,
          athlete_uuid: athlete_uuid,
          left_at: utc_now()
        }

      false ->
        []
    end
  end

  @doc """
  Exclude a competitor who is participating in a challenge providing a reason (e.g. not a paid club member).
  """
  def execute(%Challenge{} = challenge, %ExcludeCompetitorFromChallenge{} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %ExcludeCompetitorFromChallenge{
      athlete_uuid: athlete_uuid,
      reason: reason,
      excluded_at: excluded_at
    } = command

    case is_challenge_competitor?(challenge, athlete_uuid) do
      true ->
        %CompetitorExcludedFromChallenge{
          challenge_uuid: challenge_uuid,
          athlete_uuid: athlete_uuid,
          reason: reason,
          excluded_at: excluded_at
        }

      # not a competitor
      false ->
        []
    end
  end

  @doc """
  Limit a competitor who is participating in a challenge by restricting their point scoring, providing a reason (e.g. not a paid club member).
  """
  def execute(
        %Challenge{challenge_uuid: challenge_uuid} = challenge,
        %LimitCompetitorParticipationInChallenge{athlete_uuid: athlete_uuid, reason: reason}
      ) do
    if is_challenge_competitor?(challenge, athlete_uuid) &&
         !is_limited_competitor?(challenge, athlete_uuid) do
      %CompetitorParticipationInChallengeLimited{
        challenge_uuid: challenge_uuid,
        athlete_uuid: athlete_uuid,
        reason: reason
      }
    else
      # Not a competitor or already limited
      []
    end
  end

  def execute(%Challenge{} = challenge, %AllowCompetitorParticipationInChallenge{} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge
    %AllowCompetitorParticipationInChallenge{athlete_uuid: athlete_uuid} = command

    if is_limited_competitor?(challenge, athlete_uuid) do
      %CompetitorParticipationInChallengeAllowed{
        challenge_uuid: challenge_uuid,
        athlete_uuid: athlete_uuid
      }
    else
      # Not a limited competitor
      []
    end
  end

  @doc """
  Include a stage in the challenge.
  """
  def execute(%Challenge{} = challenge, %IncludeStageInChallenge{} = command) do
    %Challenge{challenge_uuid: challenge_uuid, end_date: challenge_end_date} = challenge

    %IncludeStageInChallenge{
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      name: name,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = command

    case is_included_stage?(challenge, stage_uuid) do
      true ->
        []

      false ->
        stage_included = %StageIncludedInChallenge{
          challenge_uuid: challenge_uuid,
          stage_uuid: stage_uuid,
          stage_number: stage_number,
          name: name,
          start_date: start_date,
          start_date_local: start_date_local,
          end_date: end_date,
          end_date_local: end_date_local
        }

        case Timex.diff(end_date, challenge_end_date, :seconds) do
          0 ->
            [
              stage_included,
              %ChallengeStagesConfigured{
                challenge_uuid: challenge_uuid,
                stage_uuids: included_stage_uuids(challenge) ++ [stage_uuid]
              }
            ]

          _diff ->
            stage_included
        end
    end
  end

  def execute(%Challenge{} = challenge, %RemoveStageFromChallenge{} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge
    %RemoveStageFromChallenge{stage_uuid: stage_uuid, stage_number: stage_number} = command

    case is_included_stage?(challenge, stage_uuid) do
      true ->
        [
          %StageRemovedFromChallenge{
            challenge_uuid: challenge_uuid,
            stage_uuid: stage_uuid,
            stage_number: stage_number
          }
        ]

      false ->
        []
    end
  end

  @doc """
  Cancel a challenge
  """
  def execute(%Challenge{status: status} = challenge, %CancelChallenge{} = command)
      when status in [:created, :hosted, :approved, :active] do
    %Challenge{
      challenge_uuid: challenge_uuid,
      hosted_by_club_uuid: hosted_by_club_uuid
    } = challenge

    %CancelChallenge{cancelled_by_athlete_uuid: cancelled_by_athlete_uuid} = command

    %ChallengeCancelled{
      challenge_uuid: challenge_uuid,
      cancelled_by_athlete_uuid: cancelled_by_athlete_uuid,
      hosted_by_club_uuid: hosted_by_club_uuid
    }
  end

  def execute(%Challenge{}, %CancelChallenge{}), do: {:error, :cannot_cancel_challenge}

  @doc """
  Host a created challenge.
  """
  def execute(%Challenge{status: :created} = challenge, %HostChallenge{} = command) do
    %HostChallenge{hosted_by_athlete_uuid: hosted_by_athlete_uuid} = command

    challenge
    |> Multi.new()
    |> Multi.execute(&host_challenge(&1, hosted_by_athlete_uuid))
    |> Multi.execute(&request_challenge_leaderboards/1)
    |> Multi.execute(&approve_challenge(&1, hosted_by_athlete_uuid))
    |> Multi.execute(&start_challenge/1)
    |> Multi.execute(&start_first_stage/1)
  end

  def execute(%Challenge{}, %HostChallenge{}), do: {:error, :challenge_not_created}

  def execute(%Challenge{status: :cancelled}, %ApproveChallenge{}), do: []
  def execute(%Challenge{}, %ApproveChallenge{}), do: {:error, :challenge_not_hosted}

  @doc """
  Adjust the start/end date of the challenge
  """
  def execute(%Challenge{} = challenge, %AdjustChallengeDuration{} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %AdjustChallengeDuration{
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = command

    %ChallengeDurationAdjusted{
      challenge_uuid: challenge_uuid,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    }
  end

  def execute(%Challenge{} = challenge, %AdjustChallengeIncludedActivities{} = command) do
    %Challenge{challenge_uuid: challenge_uuid, included_activity_types: existing_activity_types} =
      challenge

    %AdjustChallengeIncludedActivities{included_activity_types: included_activity_types} = command

    unless MapSet.equal?(MapSet.new(existing_activity_types), MapSet.new(included_activity_types)) do
      %ChallengeIncludedActivitiesAdjusted{
        challenge_uuid: challenge_uuid,
        included_activity_types: included_activity_types
      }
    else
      []
    end
  end

  def execute(%Challenge{} = challenge, %SetChallengeDescription{} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %SetChallengeDescription{
      description: description,
      updated_by_athlete_uuid: updated_by_athlete_uuid
    } = command

    %ChallengeDescriptionEdited{
      challenge_uuid: challenge_uuid,
      description: description,
      updated_by_athlete_uuid: updated_by_athlete_uuid
    }
  end

  @doc """
  Start the challenge, making it active.
  """
  def execute(%Challenge{status: :approved} = challenge, %StartChallenge{}) do
    challenge
    |> Multi.new()
    |> Multi.execute(&start_challenge/1)
    |> Multi.execute(&start_first_stage/1)
  end

  def execute(%Challenge{}, %StartChallenge{}), do: {:error, :challenge_not_approved}

  @doc """
  End the challenge, making it complete
  """
  def execute(%Challenge{status: :active} = challenge, %EndChallenge{}) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %ChallengeEnded{
      challenge_uuid: challenge_uuid,
      end_date: challenge.end_date,
      end_date_local: challenge.end_date_local,
      hosted_by_club_uuid: challenge.hosted_by_club_uuid
    }
  end

  def execute(%Challenge{}, %EndChallenge{}), do: {:error, :challenge_not_active}

  @doc """
  Approve the leaderboards for the challenge once it has ended.
  This will finalise the challenge leaderboards and complete the challenge.
  """
  def execute(
        %Challenge{status: :ended} = challenge,
        %ApproveChallengeLeaderboards{} = command
      ) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %ApproveChallengeLeaderboards{
      approved_by_athlete_uuid: approved_by_athlete_uuid,
      approved_by_club_uuid: approved_by_club_uuid,
      approval_message: approval_message
    } = command

    %ChallengeLeaderboardsApproved{
      challenge_uuid: challenge_uuid,
      approved_by_athlete_uuid: approved_by_athlete_uuid,
      approved_by_club_uuid: approved_by_club_uuid,
      approval_message: approval_message
    }
  end

  def execute(%Challenge{}, %ApproveChallengeLeaderboards{}),
    do: {:error, :challenge_has_not_ended}

  def execute(
        %Challenge{status: :ended, results_message: results_message},
        %PublishChallengeResults{message: results_message}
      ),
      do: []

  def execute(%Challenge{status: :ended} = stage, %PublishChallengeResults{} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = stage

    %PublishChallengeResults{
      message: message,
      published_by_athlete_uuid: published_by_athlete_uuid,
      published_by_club_uuid: published_by_club_uuid
    } = command

    %ChallengeResultsPublished{
      challenge_uuid: challenge_uuid,
      message: message,
      published_by_athlete_uuid: published_by_athlete_uuid,
      published_by_club_uuid: published_by_club_uuid
    }
  end

  def execute(%Challenge{}, %PublishChallengeResults{}), do: {:error, :challenge_has_not_ended}

  # State mutators

  def apply(%Challenge{} = challenge, %ChallengeCreated{} = event) do
    %ChallengeCreated{
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      hosted_by_club_uuid: hosted_by_club_uuid,
      hosted_by_club_name: hosted_by_club_name,
      allow_private_activities?: allow_private_activities?,
      included_activity_types: included_activity_types,
      accumulate_activities?: accumulate_activities?,
      private: private,
      created_by_athlete_uuid: created_by_athlete_uuid,
      url_slug: url_slug
    } = event

    %Challenge{
      challenge
      | challenge_uuid: challenge_uuid,
        challenge_type: challenge_type,
        name: name,
        description: description,
        start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local,
        hosted_by_club_uuid: hosted_by_club_uuid,
        hosted_by_club_name: hosted_by_club_name,
        allow_private_activities?: allow_private_activities?,
        included_activity_types: included_activity_types,
        accumulate_activities?: accumulate_activities?,
        private: private,
        created_by_athlete_uuid: created_by_athlete_uuid,
        url_slug: url_slug,
        status: :created
    }
  end

  def apply(%Challenge{} = challenge, %ChallengeGoalConfigured{} = event) do
    %ChallengeGoalConfigured{
      goal: goal,
      goal_units: goal_units,
      goal_recurrence: goal_recurrence
    } = event

    %Challenge{
      challenge
      | has_goal?: true,
        goal: goal,
        goal_units: goal_units,
        goal_recurrence: goal_recurrence
    }
  end

  def apply(%Challenge{} = challenge, %ChallengeStageRequested{}) do
    challenge
  end

  def apply(%Challenge{} = challenge, %ChallengeRenamed{name: name}) do
    %Challenge{challenge | name: name}
  end

  def apply(%Challenge{} = challenge, %CompetitorJoinedChallenge{} = event) do
    %Challenge{competitors: competitors} = challenge
    %CompetitorJoinedChallenge{athlete_uuid: athlete_uuid} = event

    %Challenge{challenge | competitors: MapSet.put(competitors, athlete_uuid)}
  end

  def apply(%Challenge{} = challenge, %CompetitorsJoinedChallenge{} = event) do
    %Challenge{competitors: competitors} = challenge
    %CompetitorsJoinedChallenge{competitors: joined} = event

    %Challenge{
      challenge
      | competitors:
          Enum.reduce(joined, competitors, fn competitor, competitors ->
            MapSet.put(competitors, competitor.athlete_uuid)
          end)
    }
  end

  def apply(%Challenge{} = challenge, %CompetitorLeftChallenge{} = event) do
    %Challenge{competitors: competitors} = challenge
    %CompetitorLeftChallenge{athlete_uuid: athlete_uuid} = event

    %Challenge{challenge | competitors: MapSet.delete(competitors, athlete_uuid)}
  end

  def apply(%Challenge{} = challenge, %CompetitorExcludedFromChallenge{} = event) do
    %Challenge{competitors: competitors, excluded_competitors: excluded_competitors} = challenge
    %CompetitorExcludedFromChallenge{athlete_uuid: athlete_uuid} = event

    %Challenge{
      challenge
      | competitors: MapSet.delete(competitors, athlete_uuid),
        excluded_competitors: MapSet.put(excluded_competitors, athlete_uuid)
    }
  end

  def apply(%Challenge{} = challenge, %CompetitorParticipationInChallengeLimited{} = event) do
    %Challenge{limited_competitors: limited_competitors} = challenge
    %CompetitorParticipationInChallengeLimited{athlete_uuid: athlete_uuid} = event

    %Challenge{challenge | limited_competitors: MapSet.put(limited_competitors, athlete_uuid)}
  end

  def apply(%Challenge{} = challenge, %CompetitorParticipationInChallengeAllowed{} = event) do
    %Challenge{limited_competitors: limited_competitors} = challenge
    %CompetitorParticipationInChallengeAllowed{athlete_uuid: athlete_uuid} = event

    %Challenge{challenge | limited_competitors: MapSet.delete(limited_competitors, athlete_uuid)}
  end

  def apply(%Challenge{} = challenge, %StageIncludedInChallenge{} = event) do
    %Challenge{stages: stages} = challenge

    %StageIncludedInChallenge{
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      name: name,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = event

    stage = %Stage{
      stage_uuid: stage_uuid,
      stage_number: stage_number,
      name: name,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      available: true
    }

    %Challenge{challenge | stages: Enum.sort_by([stage | stages], & &1.stage_number)}
  end

  def apply(%Challenge{} = challenge, %ChallengeStagesConfigured{}), do: challenge

  def apply(%Challenge{} = challenge, %StageRemovedFromChallenge{} = event) do
    %Challenge{stages: stages} = challenge
    %StageRemovedFromChallenge{stage_uuid: stage_uuid} = event

    %Challenge{
      challenge
      | stages: Enum.reject(stages, fn stage -> stage.stage_uuid == stage_uuid end)
    }
  end

  def apply(%Challenge{} = challenge, %ChallengeCancelled{}) do
    %Challenge{challenge | status: :cancelled}
  end

  def apply(%Challenge{} = challenge, %ChallengeHosted{}) do
    %Challenge{challenge | status: :hosted}
  end

  def apply(%Challenge{} = challenge, %ChallengeLeaderboardRequested{} = event) do
    %Challenge{leaderboards: leaderboards} = challenge

    %ChallengeLeaderboardRequested{
      name: name,
      description: description,
      gender: gender
    } = event

    leaderboard = %Leaderboard{
      name: name,
      description: description,
      gender: gender
    }

    %Challenge{challenge | leaderboards: leaderboards ++ [leaderboard]}
  end

  def apply(%Challenge{} = challenge, %ChallengeApproved{}) do
    %Challenge{challenge | status: :approved}
  end

  def apply(%Challenge{} = challenge, %ChallengeResultsPublished{} = event) do
    %ChallengeResultsPublished{message: message} = event

    %Challenge{challenge | results_message: message}
  end

  def apply(%Challenge{} = challenge, %ChallengeDurationAdjusted{} = event) do
    %ChallengeDurationAdjusted{
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local
    } = event

    %Challenge{
      challenge
      | start_date: start_date,
        start_date_local: start_date_local,
        end_date: end_date,
        end_date_local: end_date_local
    }
  end

  def apply(%Challenge{} = challenge, %ChallengeDescriptionEdited{} = event) do
    %ChallengeDescriptionEdited{description: description} = event

    %Challenge{challenge | description: description}
  end

  def apply(%Challenge{} = challenge, %ChallengeIncludedActivitiesAdjusted{} = event) do
    %ChallengeIncludedActivitiesAdjusted{included_activity_types: included_activity_types} = event

    %Challenge{challenge | included_activity_types: included_activity_types}
  end

  def apply(%Challenge{} = challenge, %ChallengeStarted{}) do
    %Challenge{challenge | status: :active}
  end

  def apply(%Challenge{} = challenge, %ChallengeEnded{}) do
    %Challenge{challenge | status: :ended}
  end

  def apply(%Challenge{} = challenge, _event), do: challenge

  ## Private helpers

  defp included_stage_uuids(%Challenge{} = challenge) do
    %Challenge{stages: stages} = challenge

    Enum.map(stages, fn %Stage{stage_uuid: stage_uuid} -> stage_uuid end)
  end

  defp is_challenge_competitor?(%Challenge{} = challenge, athlete_uuid) do
    %Challenge{competitors: competitors} = challenge

    MapSet.member?(competitors, athlete_uuid)
  end

  defp is_excluded_competitor?(%Challenge{} = challenge, athlete_uuid) do
    %Challenge{excluded_competitors: excluded_competitors} = challenge

    MapSet.member?(excluded_competitors, athlete_uuid)
  end

  defp is_limited_competitor?(%Challenge{} = challenge, athlete_uuid) do
    %Challenge{limited_competitors: limited_competitors} = challenge

    MapSet.member?(limited_competitors, athlete_uuid)
  end

  defp is_included_stage?(%Challenge{} = challenge, stage_uuid) do
    %Challenge{stages: stages} = challenge

    Enum.any?(stages, fn stage -> stage.stage_uuid == stage_uuid end)
  end

  defp create_challenge(%CreateChallenge{} = command) do
    %CreateChallenge{
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      restricted_to_club_members: restricted_to_club_members?,
      allow_private_activities: allow_private_activities?,
      included_activity_types: included_activity_types,
      accumulate_activities: accumulate_activities,
      hosted_by_club_uuid: hosted_by_club_uuid,
      hosted_by_club_name: hosted_by_club_name,
      created_by_athlete_uuid: created_by_athlete_uuid,
      created_by_athlete_name: created_by_athlete_name,
      private: private,
      slugger: slugger
    } = command

    # Assign URL slug from challenge name
    {:ok, url_slug} = slugger.("challenge", challenge_uuid, name)

    %ChallengeCreated{
      challenge_uuid: challenge_uuid,
      challenge_type: challenge_type,
      name: name,
      description: description,
      start_date: start_date,
      start_date_local: start_date_local,
      end_date: end_date,
      end_date_local: end_date_local,
      restricted_to_club_members?: restricted_to_club_members?,
      allow_private_activities?: allow_private_activities?,
      included_activity_types: included_activity_types,
      accumulate_activities?: accumulate_activities,
      hosted_by_club_uuid: hosted_by_club_uuid,
      hosted_by_club_name: hosted_by_club_name,
      created_by_athlete_uuid: created_by_athlete_uuid,
      created_by_athlete_name: created_by_athlete_name,
      private: private,
      url_slug: url_slug
    }
  end

  defp configure_goal(%Challenge{} = challenge, %CreateChallenge{has_goal: true} = command) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %CreateChallenge{
      goal: goal,
      goal_units: goal_units,
      goal_recurrence: goal_recurrence
    } = command

    %ChallengeGoalConfigured{
      challenge_uuid: challenge_uuid,
      goal: goal,
      goal_units: goal_units,
      goal_recurrence: goal_recurrence
    }
  end

  defp configure_goal(%Challenge{}, %CreateChallenge{}), do: []

  defp host_challenge(%Challenge{} = challenge, hosted_by_athlete_uuid) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %ChallengeHosted{
      challenge_uuid: challenge_uuid,
      hosted_by_athlete_uuid: hosted_by_athlete_uuid
    }
  end

  # Approve a challenge once it has been hosted.
  defp approve_challenge(
         %Challenge{status: :hosted} = challenge,
         approved_by_athlete_uuid
       ) do
    %Challenge{challenge_uuid: challenge_uuid} = challenge

    %ChallengeApproved{
      challenge_uuid: challenge_uuid,
      approved_by_athlete_uuid: approved_by_athlete_uuid
    }
  end

  defp approve_challenge(%Challenge{}, _approved_by_athlete_uuid), do: []

  # Immediately start challenge if start date has already passed.
  defp start_challenge(%Challenge{status: :approved} = challenge) do
    %Challenge{
      challenge_uuid: challenge_uuid,
      start_date: start_date,
      start_date_local: start_date_local
    } = challenge

    unless Timex.after?(start_date, utc_now()) do
      %ChallengeStarted{
        challenge_uuid: challenge_uuid,
        start_date: start_date,
        start_date_local: start_date_local
      }
    else
      []
    end
  end

  defp start_challenge(%Challenge{}), do: []

  # Request start of first stage, if present.
  defp start_first_stage(%Challenge{status: :active} = challenge) do
    %Challenge{challenge_uuid: challenge_uuid, stages: stages} = challenge

    case Enum.find(stages, fn stage -> stage.stage_number == 1 end) do
      %Stage{} = stage ->
        %Stage{stage_uuid: stage_uuid, start_date: start_date, stage_number: stage_number} = stage

        unless Timex.after?(start_date, utc_now()) do
          %ChallengeStageStartRequested{
            challenge_uuid: challenge_uuid,
            stage_uuid: stage_uuid,
            stage_number: stage_number
          }
        else
          []
        end

      nil ->
        []
    end
  end

  defp start_first_stage(%Challenge{}), do: []

  defp utc_now, do: SegmentChallenge.Infrastructure.DateTime.Now.to_naive()
end
