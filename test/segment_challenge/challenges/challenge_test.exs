defmodule SegmentChallenge.Challenges.ChallengeTest do
  use SegmentChallenge.AggregateCase, aggregate: SegmentChallenge.Challenges.Challenge
  use SegmentChallenge.Challenges.Challenge.Aliases

  alias SegmentChallenge.Infrastructure.DateTime.Now

  @moduletag :unit

  describe "create a segment challenge" do
    test "should be created" do
      assert_events(
        :create_segment_challenge,
        [
          {:challenge_created, challenge_type: "segment"}
        ]
      )
    end
  end

  describe "create an activity challenge" do
    test "should be created including requested stage" do
      assert_events(
        {:create_distance_challenge, has_goal: false},
        [
          {:distance_challenge_created, challenge_type: "distance"},
          fn event ->
            {:challenge_stage_requested,
             stage_type: "distance",
             stage_uuid: event.stage_uuid,
             goal: nil,
             goal_units: nil,
             has_goal?: false,
             visible?: true}
          end
        ]
      )
    end

    test "should configure a goal" do
      assert_events(
        {:create_distance_challenge,
         has_goal: true, goal: 1_250.0, goal_units: "kilometres", goal_recurrence: "none"},
        [
          {:distance_challenge_created, challenge_type: "distance"},
          {:challenge_goal_configured, goal: 1_250.0, goal_units: "kilometres"},
          fn event ->
            {:challenge_stage_requested,
             stage_type: "distance", stage_uuid: event.stage_uuid, visible?: true}
          end
        ]
      )
    end
  end

  describe "create a virtual race" do
    test "should be created including goal and requested stage" do
      assert_events(
        {:create_virtual_race, goal: 10.0, goal_units: "kilometres"},
        [
          {:virtual_race_created, challenge_type: "race"},
          {:challenge_goal_configured, goal: 10.0, goal_units: "kilometres"},
          fn event ->
            {:virtual_race_stage_requested,
             stage_type: "race",
             stage_uuid: event.stage_uuid,
             has_goal?: true,
             goal: 10.0,
             goal_units: "kilometres",
             visible?: true}
          end
        ]
      )
    end
  end

  describe "include a competitor" do
    test "should join challenge" do
      assert_events(
        [
          {:challenge_created, challenge_type: "segment"}
        ],
        {:join_challenge, athlete_uuid: "athlete1"},
        [
          {:competitor_joined_challenge, athlete_uuid: "athlete1"}
        ]
      )
    end
  end

  describe "exclude a competitor" do
    test "should remove competitor" do
      reason = "Not a paid club member"

      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:competitor_joined_challenge, athlete_uuid: "athlete1"}
        ],
        {:exclude_competitor_from_challenge, athlete_uuid: "athlete1", reason: reason},
        [
          {:competitor_excluded_from_challenge, athlete_uuid: "athlete1", reason: reason}
        ]
      )
    end

    test "should ignore requests to exclude an already excluded competitor" do
      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:competitor_joined_challenge, athlete_uuid: "athlete1"},
          {:competitor_excluded_from_challenge, athlete_uuid: "athlete1"}
        ],
        {:exclude_competitor_from_challenge, athlete_uuid: "athlete1"},
        []
      )
    end

    test "should ignore requests to include an already excluded competitor" do
      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:competitor_joined_challenge, athlete_uuid: "athlete1"},
          {:competitor_excluded_from_challenge, athlete_uuid: "athlete1"}
        ],
        {:join_challenge, athlete_uuid: "athlete1"},
        []
      )
    end
  end

  describe "limit competitor participation" do
    test "should limit competitor" do
      reason = "Not a paid club member"

      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:competitor_joined_challenge, athlete_uuid: "athlete1"}
        ],
        {:limit_competitor_participation_in_challenge, athlete_uuid: "athlete1", reason: reason},
        [
          {:competitor_participation_in_challenge_limited,
           athlete_uuid: "athlete1", reason: reason}
        ]
      )
    end
  end

  describe "adjust challenge duration" do
    test "should adjust start and end dates" do
      adjusted_start_date = ~N[2016-01-02 00:00:00]
      adjusted_start_date_local = ~N[2016-01-02 00:00:00]
      adjusted_end_date = ~N[2016-10-30 23:59:59]
      adjusted_end_date_local = ~N[2016-10-30 23:59:59]

      assert_events(
        [
          {:challenge_created, challenge_type: "segment"}
        ],
        {:adjust_challenge_duration,
         start_date: adjusted_start_date,
         start_date_local: adjusted_start_date_local,
         end_date: adjusted_end_date,
         end_date_local: adjusted_end_date_local},
        [
          {:challenge_duration_adjusted,
           start_date: adjusted_start_date,
           start_date_local: adjusted_start_date_local,
           end_date: adjusted_end_date,
           end_date_local: adjusted_end_date_local}
        ]
      )
    end
  end

  describe "include a stage" do
    test "should include a new stage" do
      assert_events(
        [
          {:challenge_created, challenge_type: "segment"}
        ],
        {:include_stage_in_challenge, stage_uuid: "stage1"},
        [
          {:stage_included_in_challenge, stage_uuid: "stage1"}
        ]
      )
    end

    test "should ignore an existing stage" do
      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:stage_included_in_challenge, stage_uuid: "stage1"}
        ],
        {:include_stage_in_challenge, stage_uuid: "stage1"},
        []
      )
    end

    test "should indicate challenge stages are complete when final stage included" do
      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:stage_included_in_challenge, stage_uuid: "stage1"}
        ],
        {:include_stage_in_challenge,
         stage_uuid: "stage2",
         start_date: ~N[2016-02-01 00:00:00],
         start_date_local: ~N[2016-02-01 00:00:00],
         end_date: ~N[2016-10-31 23:59:59],
         end_date_local: ~N[2016-10-31 23:59:59]},
        [
          {:stage_included_in_challenge,
           stage_uuid: "stage2",
           start_date: ~N[2016-02-01 00:00:00],
           start_date_local: ~N[2016-02-01 00:00:00],
           end_date: ~N[2016-10-31 23:59:59],
           end_date_local: ~N[2016-10-31 23:59:59]},
          {:challenge_stages_configured, stage_uuids: ["stage1", "stage2"]}
        ]
      )
    end
  end

  describe "host segment challenge" do
    test "should be hosted, request challenge leaderboards, and approved" do
      Now.set(~N[2015-12-31 00:00:00])

      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:stage_included_in_challenge, stage_uuid: "stage1"}
        ],
        :host_challenge,
        [
          :challenge_hosted,
          segment_leaderboards_requested(),
          :challenge_approved
        ]
      )
    end

    test "should be started when hosted after challenge start date" do
      Now.set(~N[2016-01-02 00:00:00])

      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:stage_included_in_challenge, stage_uuid: "stage1"}
        ],
        :host_challenge,
        [
          :challenge_hosted,
          segment_leaderboards_requested(),
          :challenge_approved,
          :challenge_started,
          {:challenge_stage_start_requested, stage_uuid: "stage1"}
        ]
      )
    end
  end

  describe "host activity challenge" do
    test "should be hosted, request challenge leaderboards, and approved" do
      Now.set(~N[2018-11-30 00:00:00])

      assert_events(
        [
          distance_challenge_created_with_stage()
        ],
        :host_challenge,
        [
          :challenge_hosted,
          distance_challenge_leaderboards_requested(),
          :challenge_approved
        ]
      )
    end

    test "should be started when hosted after challenge start date" do
      Now.set(~N[2018-12-02 00:00:00])

      assert_events(
        [
          distance_challenge_created_with_stage()
        ],
        :host_challenge,
        [
          :challenge_hosted,
          distance_challenge_leaderboards_requested(),
          :challenge_approved,
          {:challenge_started,
           start_date: ~N[2018-12-01 00:00:00], start_date_local: ~N[2018-12-01 00:00:00]},
          {:challenge_stage_start_requested, stage_uuid: "stage1"}
        ]
      )
    end
  end

  describe "host virtual race" do
    test "should be hosted, request challenge leaderboards, and approved" do
      Now.set(~N[2018-11-30 00:00:00])

      assert_events(
        [
          virtual_race_created()
        ],
        :host_challenge,
        [
          :challenge_hosted,
          virtual_race_leaderboards_requested(),
          :challenge_approved
        ]
      )
    end

    test "should be started when hosted after challenge start date" do
      Now.set(~N[2018-12-02 00:00:00])

      assert_events(
        [
          virtual_race_created()
        ],
        :host_challenge,
        [
          :challenge_hosted,
          virtual_race_leaderboards_requested(),
          :challenge_approved,
          {:challenge_started,
           start_date: ~N[2018-12-01 00:00:00], start_date_local: ~N[2018-12-01 00:00:00]},
          {:challenge_stage_start_requested, stage_uuid: "stage1"}
        ]
      )
    end
  end

  describe "start challenge" do
    test "should request the start of stage 1" do
      Now.set(~N[2018-12-02 00:00:00])

      assert_events(
        [
          {:challenge_created, challenge_type: "segment"},
          {:stage_included_in_challenge, stage_uuid: "stage1"},
          :challenge_hosted,
          :challenge_approved
        ],
        :start_challenge,
        [
          :challenge_started,
          {:challenge_stage_start_requested, stage_uuid: "stage1"}
        ]
      )
    end
  end

  defp segment_leaderboards_requested do
    [
      {:challenge_leaderboard_requested, gender: "M"},
      {:challenge_leaderboard_requested, gender: "F"},
      {:challenge_leaderboard_requested,
       name: "KOM",
       description: "King of the mountains",
       gender: "M",
       points: %{:mountain => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}},
      {:challenge_leaderboard_requested,
       name: "QOM",
       description: "Queen of the mountains",
       gender: "F",
       points: %{:mountain => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}},
      {:challenge_leaderboard_requested,
       name: "Sprint",
       description: "Sprint",
       gender: "M",
       points: %{:flat => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}},
      {:challenge_leaderboard_requested,
       name: "Sprint",
       description: "Sprint",
       gender: "F",
       points: %{:flat => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}}
    ]
  end

  defp distance_challenge_created_with_stage do
    [
      {:distance_challenge_created, challenge_type: "distance"},
      {:challenge_stage_requested,
       stage_type: "distance", stage_uuid: "stage1", goal: nil, goal_units: nil, has_goal?: false},
      {:stage_included_in_challenge,
       stage_uuid: "stage1",
       start_date: ~N[2018-12-01 00:00:00],
       start_date_local: ~N[2018-12-01 00:00:00],
       end_date: ~N[2018-12-31 23:59:59],
       end_date_local: ~N[2018-12-31 23:59:59]}
    ]
  end

  defp distance_challenge_leaderboards_requested do
    [
      {:challenge_leaderboard_requested,
       challenge_type: "distance",
       name: "Overall",
       description: "Overall",
       gender: "M",
       rank_by: "distance_in_metres",
       rank_order: "desc",
       points: nil},
      {:challenge_leaderboard_requested,
       challenge_type: "distance",
       name: "Overall",
       description: "Overall",
       gender: "F",
       rank_by: "distance_in_metres",
       rank_order: "desc",
       points: nil}
    ]
  end

  defp virtual_race_created do
    [
      {:virtual_race_created, challenge_type: "race"},
      {:challenge_goal_configured, goal: 10.0, goal_units: "kilometres"},
      {:virtual_race_stage_requested,
       stage_uuid: "stage1",
       stage_type: "race",
       has_goal?: true,
       goal: 10.0,
       goal_units: "kilometres",
       visible?: true},
      {:stage_included_in_challenge,
       stage_uuid: "stage1",
       start_date: ~N[2018-12-01 00:00:00],
       start_date_local: ~N[2018-12-01 00:00:00],
       end_date: ~N[2018-12-31 23:59:59],
       end_date_local: ~N[2018-12-31 23:59:59]}
    ]
  end

  defp virtual_race_leaderboards_requested do
    [
      {:challenge_leaderboard_requested,
       challenge_type: "race",
       name: "Overall",
       description: "Overall",
       gender: "M",
       rank_by: "elapsed_time_in_seconds",
       rank_order: "asc",
       points: nil,
       has_goal?: true,
       goal: 10.0,
       goal_units: "kilometres"},
      {:challenge_leaderboard_requested,
       challenge_type: "race",
       name: "Overall",
       description: "Overall",
       gender: "F",
       rank_by: "elapsed_time_in_seconds",
       rank_order: "asc",
       points: nil,
       has_goal?: true,
       goal: 10.0,
       goal_units: "kilometres"}
    ]
  end
end
