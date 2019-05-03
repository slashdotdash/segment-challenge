defmodule SegmentChallenge.Authorisation.Policies.ChallengePolicy do
  alias SegmentChallenge.Authorisation.User

  alias SegmentChallenge.Commands.{
    ApproveChallengeLeaderboards,
    CreateChallenge,
    CancelChallenge,
    HostChallenge,
    JoinChallenge,
    LeaveChallenge,
    PublishChallengeResults,
    RenameChallenge,
    SetChallengeDescription
  }

  alias SegmentChallenge.Projections.ChallengeProjection
  alias SegmentChallenge.Repo

  def commands(%User{} = user, %ChallengeProjection{} = challenge) do
    user
    |> challenge_commands(challenge)
    |> Enum.filter(fn {_name, command} -> can?(user, :dispatch, command, challenge) end)
  end

  def command(name, %User{} = user, %ChallengeProjection{} = challenge) do
    user
    |> challenge_commands(challenge)
    |> Enum.find(fn
      {^name, command} -> can?(user, :dispatch, command, challenge)
      _ -> false
    end)
  end

  def can?(%User{} = user, :dispatch, %{challenge_uuid: challenge_uuid} = command) do
    challenge = Repo.get(ChallengeProjection, challenge_uuid)

    can?(user, :dispatch, command, challenge)
  end

  def can?(_user, _action, _command), do: false

  # ensure the challenge doesn't already exist
  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %CreateChallenge{created_by_athlete_uuid: athlete_uuid},
        nil
      ),
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %HostChallenge{challenge_uuid: challenge_uuid, hosted_by_athlete_uuid: athlete_uuid},
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          status: "pending"
        }
      ),
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %JoinChallenge{challenge_uuid: challenge_uuid, athlete_uuid: athlete_uuid},
        %ChallengeProjection{challenge_uuid: challenge_uuid, status: status}
      )
      when status in ["upcoming", "active"],
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %LeaveChallenge{challenge_uuid: challenge_uuid, athlete_uuid: athlete_uuid},
        %ChallengeProjection{challenge_uuid: challenge_uuid, status: status}
      )
      when status in ["upcoming", "active"],
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %PublishChallengeResults{
          challenge_uuid: challenge_uuid,
          published_by_athlete_uuid: athlete_uuid,
          published_by_club_uuid: club_uuid
        },
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          hosted_by_club_uuid: club_uuid,
          status: "past"
        }
      ),
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %ApproveChallengeLeaderboards{
          challenge_uuid: challenge_uuid,
          approved_by_athlete_uuid: athlete_uuid,
          approved_by_club_uuid: club_uuid
        },
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          hosted_by_club_uuid: club_uuid,
          status: "past",
          approved: false
        }
      ),
      do: true

  # can only cancel pending, upcoming, and active challenges
  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %CancelChallenge{challenge_uuid: challenge_uuid, cancelled_by_athlete_uuid: athlete_uuid},
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          status: challenge_status
        }
      )
      when challenge_status in ["pending", "upcoming", "active"],
      do: true

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %RenameChallenge{challenge_uuid: challenge_uuid, renamed_by_athlete_uuid: athlete_uuid},
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid,
          status: status
        }
      ) do
    case status do
      "past" -> false
      _ -> true
    end
  end

  def can?(
        %User{athlete_uuid: athlete_uuid},
        :dispatch,
        %SetChallengeDescription{
          challenge_uuid: challenge_uuid,
          updated_by_athlete_uuid: athlete_uuid
        },
        %ChallengeProjection{
          challenge_uuid: challenge_uuid,
          created_by_athlete_uuid: athlete_uuid
        }
      ),
      do: true

  def can?(_user, _action, _command, _challenge), do: false

  defp challenge_commands(
         %User{athlete_uuid: athlete_uuid},
         %ChallengeProjection{challenge_uuid: challenge_uuid, hosted_by_club_uuid: club_uuid}
       ) do
    [
      approve_challenge: %ApproveChallengeLeaderboards{
        challenge_uuid: challenge_uuid,
        approved_by_athlete_uuid: athlete_uuid,
        approved_by_club_uuid: club_uuid
      },
      cancel_challenge: %CancelChallenge{
        challenge_uuid: challenge_uuid,
        cancelled_by_athlete_uuid: athlete_uuid
      },
      leave_challenge: %LeaveChallenge{
        challenge_uuid: challenge_uuid,
        athlete_uuid: athlete_uuid
      },
      publish_challenge_results: %PublishChallengeResults{
        challenge_uuid: challenge_uuid,
        published_by_athlete_uuid: athlete_uuid,
        published_by_club_uuid: club_uuid
      },
      rename_challenge: %RenameChallenge{
        challenge_uuid: challenge_uuid,
        renamed_by_athlete_uuid: athlete_uuid
      },
      set_challenge_description: %SetChallengeDescription{
        challenge_uuid: challenge_uuid,
        updated_by_athlete_uuid: athlete_uuid
      }
    ]
  end
end
