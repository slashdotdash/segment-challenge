defmodule SegmentChallenge.ChallengeFactory do
  use SegmentChallenge.Challenges.Challenge.Aliases

  alias SegmentChallenge.ChallengeFactory

  defmacro __using__(_opts) do
    quote do
      @challenge_uuid UUID.uuid4()
      @stage_uuid UUID.uuid4()
      @athlete_uuid "athlete-5704447"

      def challenge_factory do
        %{
          challenge_uuid: @challenge_uuid,
          challenge_type: "segment",
          name: "VC Venta Segment of the Month 2016",
          description: """
          A friendly competition open to VC Venta members.
          Each month the organiser will nominate a Strava segment.
          Whoever records the fastest time (male and female) over the segment is the winner.

          Placings contribute to the overall competitions.
          """,
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-10-31 23:59:59],
          end_date_local: ~N[2016-10-31 23:59:59],
          restricted_to_club_members: true,
          allow_private_activities: false,
          included_activity_types: [],
          accumulate_activities: false,
          hosted_by_club_uuid: "club-7289",
          hosted_by_club_name: "VC Venta",
          created_by_athlete_uuid: @athlete_uuid,
          created_by_athlete_name: "Ben Smith",
          private: false,
          url_slug: "vc-venta-segment-of-the-month-2016",
          slugger: &ChallengeFactory.slugify/3
        }
      end

      def create_challenge_factory do
        struct(CreateChallenge, build(:challenge))
      end

      def create_segment_challenge_factory do
        struct(CreateChallenge, build(:challenge))
      end

      def create_distance_challenge_factory do
        %CreateChallenge{
          challenge_uuid: @challenge_uuid,
          challenge_type: "distance",
          name: "December Cycling Distance Challenge",
          description: """
          The Distance Challenge is a monthly opportunity to push yourself.
          Whether you start the Challenge at the beginning of the month or join in the last week, set a distance goal and make it happen.
          You’ll get progress updates to keep you motivated along the way.
          Make it to 1,250km and you’ll earn a finisher’s badge.
          """,
          start_date: ~N[2018-12-01 00:00:00],
          start_date_local: ~N[2018-12-01 00:00:00],
          end_date: ~N[2018-12-31 23:59:59],
          end_date_local: ~N[2018-12-31 23:59:59],
          restricted_to_club_members: true,
          allow_private_activities: true,
          accumulate_activities: true,
          included_activity_types: ["Ride"],
          has_goal: true,
          goal: 1250.0,
          goal_units: "kilometres",
          goal_recurrence: "none",
          stages: nil,
          hosted_by_club_uuid: "club-7289",
          hosted_by_club_name: "VC Venta",
          created_by_athlete_uuid: @athlete_uuid,
          created_by_athlete_name: "Ben Smith",
          private: false,
          slugger: &ChallengeFactory.slugify/3
        }
      end

      def create_virtual_race_factory do
        %CreateChallenge{
          challenge_uuid: @challenge_uuid,
          challenge_type: "race",
          name: "December 10K Virtual Race",
          description: """
          Whether you join an organized race, compete with friends or head out on your own, remember to have fun and give it your all.

          Athletes who complete the 10k Virtual Race will receive a digital finisher's badge in their Trophy Case.
          """,
          start_date: ~N[2018-12-01 00:00:00],
          start_date_local: ~N[2018-12-01 00:00:00],
          end_date: ~N[2018-12-31 23:59:59],
          end_date_local: ~N[2018-12-31 23:59:59],
          restricted_to_club_members: true,
          allow_private_activities: false,
          accumulate_activities: false,
          included_activity_types: ["Run"],
          has_goal: true,
          goal: 10.0,
          goal_units: "kilometres",
          goal_recurrence: "none",
          stages: nil,
          hosted_by_club_uuid: "club-7289",
          hosted_by_club_name: "VC Venta",
          created_by_athlete_uuid: @athlete_uuid,
          created_by_athlete_name: "Ben Smith",
          private: false,
          slugger: &ChallengeFactory.slugify/3
        }
      end

      def challenge_created_factory do
        struct(ChallengeCreated, build(:challenge))
      end

      def distance_challenge_created_factory do
        %ChallengeCreated{
          challenge_uuid: @challenge_uuid,
          challenge_type: "distance",
          name: "December Cycling Distance Challenge",
          description: """
          The Distance Challenge is a monthly opportunity to push yourself.
          Whether you start the Challenge at the beginning of the month or join in the last week, set a distance goal and make it happen.
          You’ll get progress updates to keep you motivated along the way.
          Make it to 1,250km and you’ll earn a finisher’s badge.
          """,
          start_date: ~N[2018-12-01 00:00:00],
          start_date_local: ~N[2018-12-01 00:00:00],
          end_date: ~N[2018-12-31 23:59:59],
          end_date_local: ~N[2018-12-31 23:59:59],
          restricted_to_club_members?: true,
          allow_private_activities?: true,
          included_activity_types: ["Ride"],
          accumulate_activities?: true,
          hosted_by_club_uuid: "club-7289",
          hosted_by_club_name: "VC Venta",
          created_by_athlete_uuid: @athlete_uuid,
          created_by_athlete_name: "Ben Smith",
          private: false,
          url_slug: "december-cycling-distance-challenge"
        }
      end

      def virtual_race_created_factory do
        %ChallengeCreated{
          challenge_uuid: @challenge_uuid,
          challenge_type: "race",
          name: "December 10K Virtual Race",
          description: """
          Whether you join an organized race, compete with friends or head out on your own, remember to have fun and give it your all.

          Athletes who complete the 10k Virtual Race will receive a digital finisher's badge in their Trophy Case.
          """,
          start_date: ~N[2018-12-01 00:00:00],
          start_date_local: ~N[2018-12-01 00:00:00],
          end_date: ~N[2018-12-31 23:59:59],
          end_date_local: ~N[2018-12-31 23:59:59],
          restricted_to_club_members?: true,
          allow_private_activities?: false,
          included_activity_types: ["Run"],
          accumulate_activities?: false,
          hosted_by_club_uuid: "club-7289",
          hosted_by_club_name: "VC Venta",
          created_by_athlete_uuid: @athlete_uuid,
          created_by_athlete_name: "Ben Smith",
          private: false,
          url_slug: "december-10k-virtual-race"
        }
      end

      def challenge_stage_requested_factory do
        %ChallengeStageRequested{
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_number: 1,
          stage_type: "distance",
          name: "December Cycling Distance Challenge",
          description: """
          The Distance Challenge is a monthly opportunity to push yourself.
          Whether you start the Challenge at the beginning of the month or join in the last week, set a distance goal and make it happen.
          You’ll get progress updates to keep you motivated along the way.
          Make it to 1,250km and you’ll earn a finisher’s badge.
          """,
          start_date: ~N[2018-12-01 00:00:00],
          start_date_local: ~N[2018-12-01 00:00:00],
          end_date: ~N[2018-12-31 23:59:59],
          end_date_local: ~N[2018-12-31 23:59:59],
          allow_private_activities?: true,
          included_activity_types: ["Ride"],
          accumulate_activities?: true,
          has_goal?: true,
          goal: 1250.0,
          goal_units: "kilometres",
          visible?: false,
          created_by_athlete_uuid: @athlete_uuid
        }
      end

      def virtual_race_stage_requested_factory do
        %ChallengeStageRequested{
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_number: 1,
          stage_type: "race",
          name: "December 10K Virtual Race",
          description: """
          Whether you join an organized race, compete with friends or head out on your own, remember to have fun and give it your all.

          Athletes who complete the 10k Virtual Race will receive a digital finisher's badge in their Trophy Case.
          """,
          start_date: ~N[2018-12-01 00:00:00],
          start_date_local: ~N[2018-12-01 00:00:00],
          end_date: ~N[2018-12-31 23:59:59],
          end_date_local: ~N[2018-12-31 23:59:59],
          allow_private_activities?: false,
          included_activity_types: ["Run"],
          accumulate_activities?: false,
          has_goal?: true,
          goal: 10.0,
          goal_units: "kilometres",
          visible?: true,
          created_by_athlete_uuid: @athlete_uuid
        }
      end

      def challenge_goal_configured_factory do
        %ChallengeGoalConfigured{
          challenge_uuid: @challenge_uuid,
          goal: 1_250.0,
          goal_units: "kilometres",
          goal_recurrence: "none"
        }
      end

      def join_challenge_factory do
        %JoinChallenge{
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          gender: "M"
        }
      end

      def competitor_joined_challenge_factory do
        %CompetitorJoinedChallenge{
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          gender: "M"
        }
      end

      def exclude_competitor_from_challenge_factory do
        %ExcludeCompetitorFromChallenge{
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          reason: "Not a paid club member"
        }
      end

      def competitor_excluded_from_challenge_factory do
        %CompetitorExcludedFromChallenge{
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          reason: "Not a paid club member"
        }
      end

      def limit_competitor_participation_in_challenge_factory do
        %LimitCompetitorParticipationInChallenge{
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          reason: "Not a paid club member"
        }
      end

      def competitor_participation_in_challenge_limited_factory do
        %CompetitorParticipationInChallengeLimited{
          challenge_uuid: @challenge_uuid,
          athlete_uuid: @athlete_uuid,
          reason: "Not a paid club member"
        }
      end

      def adjust_challenge_duration_factory do
        %AdjustChallengeDuration{
          challenge_uuid: @challenge_uuid,
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-10-31 23:59:59],
          end_date_local: ~N[2016-10-31 23:59:59]
        }
      end

      def challenge_duration_adjusted_factory do
        %ChallengeDurationAdjusted{
          challenge_uuid: @challenge_uuid,
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-10-31 23:59:59],
          end_date_local: ~N[2016-10-31 23:59:59]
        }
      end

      def include_stage_in_challenge_factory do
        %IncludeStageInChallenge{
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_number: 1,
          name: "VCV Sleepers Hill",
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-01-31 23:59:59],
          end_date_local: ~N[2016-01-31 23:59:59]
        }
      end

      def stage_included_in_challenge_factory do
        %StageIncludedInChallenge{
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_number: 1,
          name: "VCV Sleepers Hill",
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00],
          end_date: ~N[2016-01-31 23:59:59],
          end_date_local: ~N[2016-01-31 23:59:59]
        }
      end

      def challenge_stages_configured_factory do
        %ChallengeStagesConfigured{challenge_uuid: @challenge_uuid}
      end

      def host_challenge_factory do
        %HostChallenge{
          challenge_uuid: @challenge_uuid,
          hosted_by_athlete_uuid: @athlete_uuid
        }
      end

      def challenge_hosted_factory do
        %ChallengeHosted{
          challenge_uuid: @challenge_uuid,
          hosted_by_athlete_uuid: @athlete_uuid
        }
      end

      def challenge_leaderboard_requested_factory do
        %ChallengeLeaderboardRequested{
          challenge_uuid: @challenge_uuid,
          challenge_type: "segment",
          name: "GC",
          description: "General classification",
          gender: "M",
          points: [15, 12, 10, 8, 6, 5, 4, 3, 2, 1],
          rank_by: "points",
          rank_order: "desc",
          has_goal?: false
        }
      end

      def challenge_approved_factory do
        %ChallengeApproved{
          challenge_uuid: @challenge_uuid,
          approved_by_athlete_uuid: @athlete_uuid
        }
      end

      def start_challenge_factory do
        %StartChallenge{
          challenge_uuid: @challenge_uuid
        }
      end

      def challenge_started_factory do
        %ChallengeStarted{
          challenge_uuid: @challenge_uuid,
          start_date: ~N[2016-01-01 00:00:00],
          start_date_local: ~N[2016-01-01 00:00:00]
        }
      end

      def challenge_stage_start_requested_factory do
        %ChallengeStageStartRequested{
          challenge_uuid: @challenge_uuid,
          stage_uuid: @stage_uuid,
          stage_number: 1
        }
      end
    end
  end

  def slugify(_context, _source_uuid, text),
    do: {:ok, Slugger.slugify_downcase(text)}
end
