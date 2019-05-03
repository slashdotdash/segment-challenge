defmodule SegmentChallenge.UseCases.CreateChallengeUseCase do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use SegmentChallenge.Challenges.Challenge.Aliases

  import Commanded.Assertions.EventAssertions
  import SegmentChallenge.Factory

  alias Commanded.Commands.ExecutionResult
  alias SegmentChallenge.{Repo, Router}
  alias SegmentChallenge.Strava.StravaAccess
  alias SegmentChallenge.Commands.{ImportAthlete, JoinClub}
  alias SegmentChallenge.Infrastructure.DateTime.Now

  def create_challenge(_context), do: do_create_challenge([])

  def create_challenge_as(attrs), do: do_create_challenge(attrs)

  def create_distance_challenge(_context) do
    do_create_challenge(
      name: "October Cycling Distance Challenge",
      challenge_type: "distance",
      start_date: ~N[2018-10-01 00:00:00],
      start_date_local: ~N[2018-10-01 00:00:00],
      end_date: ~N[2018-10-31 23:59:59],
      end_date_local: ~N[2018-10-31 23:59:59],
      allow_private_activities: true,
      included_activity_types: ["Ride"],
      accumulate_activities: true,
      has_goal: false
    )
  end

  def create_distance_challenge_with_goal(_context) do
    do_create_challenge(
      name: "October Cycling Distance Challenge",
      description: "Can you ride 1,250km in October 2018?",
      challenge_type: "distance",
      start_date: ~N[2018-10-01 00:00:00],
      start_date_local: ~N[2018-10-01 00:00:00],
      end_date: ~N[2018-10-31 23:59:59],
      end_date_local: ~N[2018-10-31 23:59:59],
      allow_private_activities: true,
      included_activity_types: ["Ride"],
      accumulate_activities: true,
      has_goal: true,
      goal: 1250.0,
      goal_units: "kilometres",
      goal_recurrence: "none"
    )
  end

  def create_distance_challenge_with_short_goal(_context) do
    do_create_challenge(
      name: "October Cycling Distance Challenge",
      challenge_type: "distance",
      start_date: ~N[2018-10-01 00:00:00],
      start_date_local: ~N[2018-10-01 00:00:00],
      end_date: ~N[2018-10-31 23:59:59],
      end_date_local: ~N[2018-10-31 23:59:59],
      allow_private_activities: true,
      included_activity_types: ["Ride"],
      accumulate_activities: true,
      has_goal: true,
      goal: 1.0,
      goal_units: "miles",
      goal_recurrence: "none"
    )
  end

  def create_multi_stage_distance_challenge_with_goal(_context) do
    alias SegmentChallenge.Commands.CreateChallenge.ChallengeStage

    do_create_challenge(
      name: "October Cycling Distance Challenge",
      challenge_type: "distance",
      start_date: ~N[2018-10-15 00:00:00],
      start_date_local: ~N[2018-10-15 00:00:00],
      end_date: ~N[2018-10-31 23:59:59],
      end_date_local: ~N[2018-10-31 23:59:59],
      allow_private_activities: true,
      included_activity_types: ["Ride"],
      accumulate_activities: true,
      has_goal: true,
      goal: 1.0,
      goal_units: "miles",
      goal_recurrence: "week",
      stages: [
        %ChallengeStage{
          name: "Week 1",
          description: "Week 1",
          stage_number: 1,
          start_date: ~N[2018-10-15 00:00:00],
          start_date_local: ~N[2018-10-15 00:00:00],
          end_date: ~N[2018-10-21 23:59:59],
          end_date_local: ~N[2018-10-21 23:59:59]
        },
        %ChallengeStage{
          name: "Week 2",
          description: "Week 2",
          stage_number: 2,
          start_date: ~N[2018-10-22 00:00:00],
          start_date_local: ~N[2018-10-22 00:00:00],
          end_date: ~N[2018-10-31 23:59:59],
          end_date_local: ~N[2018-10-31 23:59:59]
        }
      ]
    )
  end

  def create_virtual_race_challenge(_context) do
    do_create_challenge(
      name: "December 5K Virtual Race",
      challenge_type: "race",
      start_date: ~N[2018-12-01 00:00:00],
      start_date_local: ~N[2018-12-01 00:00:00],
      end_date: ~N[2018-12-31 23:59:59],
      end_date_local: ~N[2018-12-31 23:59:59],
      allow_private_activities: false,
      included_activity_types: ["Run"],
      accumulate_activities: false,
      has_goal: true,
      goal: 5.0,
      goal_units: "kilometres",
      goal_recurrence: "none"
    )
  end

  def create_private_challenge(_context) do
    use_cassette "challenge/create_private_challenge#7289", match_requests_on: [:query] do
      do_create_challenge(private: true)
    end
  end

  def create_future_challenge(_context) do
    now = utc_now()

    use_cassette "challenge/create_challenge#7289", match_requests_on: [:query] do
      do_create_challenge(
        utc_now: now,
        start_date: Timex.add(now, Timex.Duration.from_days(1)),
        start_date_local: Timex.add(now, Timex.Duration.from_days(1)),
        end_date: Timex.add(now, Timex.Duration.from_weeks(1)),
        end_date_local: Timex.add(now, Timex.Duration.from_weeks(1))
      )
    end
  end

  def athlete_join_challenge(context) do
    %{challenge_uuid: challenge_uuid} = context

    dispatch(:join_challenge,
      challenge_uuid: challenge_uuid,
      athlete_uuid: "athlete-5704447",
      gender: "M"
    )
  end

  def athlete_leave_challenge(context) do
    %{athlete_uuid: athlete_uuid, challenge_uuid: challenge_uuid} = context

    command = %LeaveChallenge{athlete_uuid: athlete_uuid, challenge_uuid: challenge_uuid}

    Router.dispatch(command)
  end

  def second_athlete_join_challenge(context) do
    %{challenge_uuid: challenge_uuid} = context

    dispatch(:join_challenge,
      challenge_uuid: challenge_uuid,
      athlete_uuid: "athlete-123456",
      gender: "M"
    )
  end

  def host_challenge(context) do
    :ok =
      Router.dispatch(%HostChallenge{
        challenge_uuid: context[:challenge_uuid],
        hosted_by_athlete_uuid: context[:athlete_uuid]
      })

    wait_for_event(
      ChallengeApproved,
      fn event -> event.challenge_uuid == context[:challenge_uuid] end
    )

    context
  end

  def approve_challenge(context) do
    :ok =
      Router.dispatch(%ApproveChallenge{
        challenge_uuid: context[:challenge_uuid],
        approved_by_athlete_uuid: context[:athlete_uuid]
      })

    wait_for_event(
      ChallengeApproved,
      fn event -> event.challenge_uuid == context[:challenge_uuid] end
    )

    :ok
  end

  def start_challenge(context) do
    :ok = Router.dispatch(%StartChallenge{challenge_uuid: context[:challenge_uuid]})

    wait_for_event(
      ChallengeStarted,
      fn event -> event.challenge_uuid == context[:challenge_uuid] end
    )

    :ok
  end

  def end_challenge(context) do
    :ok = Router.dispatch(%EndChallenge{challenge_uuid: context[:challenge_uuid]})

    wait_for_event(ChallengeEnded, fn event ->
      event.challenge_uuid == context[:challenge_uuid]
    end)

    :ok
  end

  def cancel_challenge(context) do
    :ok =
      Router.dispatch(%CancelChallenge{
        challenge_uuid: context[:challenge_uuid],
        cancelled_by_athlete_uuid: context[:athlete_uuid]
      })

    wait_for_event(ChallengeCancelled, fn event ->
      event.challenge_uuid == context[:challenge_uuid]
    end)

    :ok
  end

  def exclude_competitor_from_challenge(context) do
    :ok =
      Router.dispatch(%ExcludeCompetitorFromChallenge{
        challenge_uuid: context[:challenge_uuid],
        athlete_uuid: context[:athlete_uuid],
        reason: "Not a first claim club member",
        excluded_at: utc_now()
      })

    wait_for_event(CompetitorExcludedFromChallenge, fn event ->
      event.athlete_uuid == context[:athlete_uuid]
    end)

    :ok
  end

  def limit_competitor_participation(context) do
    :ok =
      Router.dispatch(%LimitCompetitorParticipationInChallenge{
        challenge_uuid: context[:challenge_uuid],
        athlete_uuid: context[:athlete_uuid],
        reason: "Not a first claim club member"
      })

    wait_for_event(CompetitorParticipationInChallengeLimited, fn event ->
      event.athlete_uuid == context[:athlete_uuid]
    end)

    :ok
  end

  def adjust_challenge_duration(context) do
    %{challenge_uuid: challenge_uuid} = context

    Router.dispatch(%AdjustChallengeDuration{
      challenge_uuid: challenge_uuid,
      start_date: ~N[2016-01-02 00:00:00],
      start_date_local: ~N[2016-01-02 00:00:00],
      end_date: ~N[2016-10-30 23:59:59],
      end_date_local: ~N[2016-10-30 23:59:59]
    })
  end

  def adjust_challenge_included_activities(context) do
    %{challenge_uuid: challenge_uuid} = context

    Router.dispatch(%AdjustChallengeIncludedActivities{
      challenge_uuid: challenge_uuid,
      included_activity_types: ["Run"]
    })
  end

  defp do_create_challenge(attrs) do
    club_uuid = UUID.uuid4()

    context =
      Keyword.merge(
        [
          challenge_uuid: UUID.uuid4(),
          strava_club_id: 7289,
          club_uuid: club_uuid,
          hosted_by_club_uuid: club_uuid,
          athlete_uuid: "athlete-5704447",
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          private: false
        ],
        attrs
      )

    # Set current date in past to ensure challenge start/end date validation passes
    Now.set(context[:start_date])

    :ok = dispatch(:import_club, club_uuid: context[:club_uuid])

    :ok =
      Router.dispatch(
        struct(
          ImportAthlete,
          build(:athlete, %{
            athlete_uuid: context[:athlete_uuid],
            strava_id: 5_704_447,
            gender: "M"
          })
        )
      )

    assign_strava_access(context[:athlete_uuid])

    :ok =
      Router.dispatch(%JoinClub{
        athlete_uuid: context[:athlete_uuid],
        club_uuid: context[:club_uuid]
      })

    {:ok, %ExecutionResult{events: events}} =
      dispatch(
        :create_challenge,
        Keyword.take(context, [
          :challenge_uuid,
          :challenge_type,
          :name,
          :description,
          :start_date,
          :start_date_local,
          :end_date,
          :end_date_local,
          :allow_private_activities,
          :included_activity_types,
          :accumulate_activities,
          :has_goal,
          :goal,
          :goal_units,
          :goal_recurrence,
          :stages,
          :hosted_by_club_uuid,
          :hosted_by_club_name,
          :created_by_athlete_uuid,
          :created_by_athlete_name,
          :private,
          :stages
        ]),
        consistency: :strong,
        include_execution_result: true
      )

    Enum.reduce(events, context, fn
      %ChallengeStageRequested{} = event, context ->
        %ChallengeStageRequested{stage_uuid: stage_uuid} = event

        context
        |> Keyword.put_new(:stage_uuid, stage_uuid)
        |> Keyword.update(:stage_uuids, [stage_uuid], fn stage_uuids ->
          Enum.reverse([stage_uuid | stage_uuids])
        end)

      _event, context ->
        context
    end)
  end

  # Assign Strava access & refresh tokens.
  defp assign_strava_access(athlete_uuid) do
    access_token = Application.get_env(:strava, :access_token)
    refresh_token = Application.get_env(:strava, :refresh_token)

    strava_access = %StravaAccess{
      athlete_uuid: athlete_uuid,
      access_token: access_token,
      refresh_token: refresh_token
    }

    Repo.insert(
      strava_access,
      on_conflict: [set: [access_token: access_token, refresh_token: refresh_token]],
      conflict_target: [:athlete_uuid]
    )
  end

  defp dispatch(command, attrs, dispatch_opts \\ []) do
    command = build(command, attrs)

    Router.dispatch(command, dispatch_opts)
  end

  defp utc_now, do: Now.to_naive() |> NaiveDateTime.truncate(:second)
end
