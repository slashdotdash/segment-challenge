defmodule SegmentChallenge.Leaderboards.ChallengeLeaderboardTest do
  use SegmentChallenge.AggregateCase,
    aggregate: SegmentChallenge.Leaderboards.ChallengeLeaderboard

  use SegmentChallenge.Leaderboards.ChallengeLeaderboard.Aliases

  alias SegmentChallenge.Events.ChallengeLeaderboardRanked.Ranking

  @moduletag :unit

  test "create challenge leaderboard ranked by points" do
    assert_events(
      {:create_challenge_leaderboard, rank_by: "points", rank_order: "desc"},
      [
        {:challenge_leaderboard_created, rank_by: "points", rank_order: "desc"}
      ]
    )
  end

  test "create challenge leaderboard ranked by distance in metres" do
    assert_events(
      {:create_challenge_leaderboard,
       challenge_type: "distance", rank_by: "distance_in_metres", rank_order: "desc"},
      [
        {:challenge_leaderboard_created,
         challenge_type: "distance", rank_by: "distance_in_metres", rank_order: "desc"}
      ]
    )
  end

  test "create distance challenge leaderboard ranked by goals" do
    assert_events(
      {:create_challenge_leaderboard,
       challenge_type: "distance", rank_by: "goals", rank_order: "desc", has_goal: true},
      [
        {:challenge_leaderboard_created,
         challenge_type: "distance", rank_by: "goals", rank_order: "desc", has_goal?: true}
      ]
    )
  end

  describe "assign points to athlete from segment stage leaderboard rank" do
    test "when leaderboard contains no entries" do
      assert_events(
        :challenge_leaderboard_created,
        :assign_points_from_stage_leaderboard,
        [
          :athlete_accumulated_points_in_challenge_leaderboard,
          :challenge_leaderbord_ranked
        ]
      )
    end

    test "when point scoring is determined by stage type and leaderboard contains no entries" do
      assert_events(
        {:challenge_leaderboard_created,
         points: %{:mountain => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}},
        :assign_points_from_stage_leaderboard,
        [
          {:athlete_accumulated_points_in_challenge_leaderboard, points: 10},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1}
           ]}
        ]
      )
    end

    test "when point scoring is adjusted for the stage and leaderboard contains no entries" do
      assert_events(
        {:challenge_leaderboard_created,
         points: %{:mountain => [10, 8, 6, 4, 2], :rolling => [5, 4, 3, 2, 1]}},
        {:assign_points_from_stage_leaderboard, points_adjustment: "queen"},
        [
          {:athlete_accumulated_points_in_challenge_leaderboard, points: 20},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1}
           ]}
        ]
      )
    end

    test "when point scoring is adjusted for double points and leaderboard is GC" do
      assert_events(
        {:challenge_leaderboard_created, points: [10, 8, 6, 4, 2]},
        {:assign_points_from_stage_leaderboard, points_adjustment: "double"},
        [
          {:athlete_accumulated_points_in_challenge_leaderboard, points: 20},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1}
           ]}
        ]
      )
    end

    test "when point scoring is adjusted for the queen stage and leaderboard is GC" do
      assert_events(
        {:challenge_leaderboard_created, points: [10, 8, 6, 4, 2]},
        {:assign_points_from_stage_leaderboard, points_adjustment: "queen"},
        [
          {:athlete_accumulated_points_in_challenge_leaderboard, points: 10},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1}
           ]}
        ]
      )
    end

    test "when point scoring is adjusted for zero points and leaderboard is GC" do
      assert_events(
        {:challenge_leaderboard_created, points: [10, 8, 6, 4, 2]},
        {:assign_points_from_stage_leaderboard, points_adjustment: "preview"},
        []
      )
    end

    test "when leaderboard already contains an entry for the athlete" do
      assert_events(
        [
          :challenge_leaderboard_created,
          :athlete_accumulated_points_in_challenge_leaderboard,
          :challenge_leaderbord_ranked
        ],
        :assign_points_from_stage_leaderboard,
        [
          :athlete_accumulated_points_in_challenge_leaderboard
        ]
      )
    end

    test "when two athletes are assigned points from stage leaderboard" do
      assert_events(
        [
          :challenge_leaderboard_created
        ],
        {:assign_points_from_stage_leaderboard,
         entries: [
           %{rank: 1, athlete_uuid: "athlete1"},
           %{rank: 2, athlete_uuid: "athlete2"}
         ]},
        [
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete1", points: 15},
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete2", points: 12},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1},
             %Ranking{athlete_uuid: "athlete2", rank: 2}
           ]}
        ]
      )
    end

    test "when leaderboard contains another athlete with fewer points" do
      assert_events(
        [
          :challenge_leaderboard_created,
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete1", points: 15},
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete2", points: 12},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1},
             %Ranking{athlete_uuid: "athlete2", rank: 2}
           ]}
        ],
        {:assign_points_from_stage_leaderboard,
         entries: [
           %{rank: 1, athlete_uuid: "athlete3"}
         ]},
        [
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete3", points: 15},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete3", rank: 1}
           ],
           positions_lost: [
             %Ranking{athlete_uuid: "athlete2", rank: 3, positions_changed: 1}
           ]}
        ]
      )
    end
  end

  describe "assign score to athlete from distance stage leaderboard activity" do
    test "when leaderboard contains no entries" do
      assert_events(
        [
          {:challenge_leaderboard_created,
           challenge_type: "distance", rank_by: "distance_in_metres", rank_order: "desc"}
        ],
        {:assign_points_from_stage_leaderboard,
         stage_type: "distance",
         entries: [
           %{
             rank: 1,
             athlete_uuid: "athlete1",
             elapsed_time_in_seconds: 200,
             moving_time_in_seconds: 200,
             distance_in_metres: 2_000,
             elevation_gain_in_metres: 200,
             stage_effort_count: 2
           },
           %{
             rank: 2,
             athlete_uuid: "athlete2",
             elapsed_time_in_seconds: 100,
             moving_time_in_seconds: 100,
             distance_in_metres: 1_000,
             elevation_gain_in_metres: 100,
             stage_effort_count: 1
           }
         ]},
        [
          {:athlete_accumulated_activity_in_challenge_leaderboard,
           challenge_type: "distance",
           athlete_uuid: "athlete1",
           elapsed_time_in_seconds: 200,
           moving_time_in_seconds: 200,
           distance_in_metres: 2_000,
           elevation_gain_in_metres: 200,
           activity_count: 2},
          {:athlete_accumulated_activity_in_challenge_leaderboard,
           challenge_type: "distance",
           athlete_uuid: "athlete2",
           elapsed_time_in_seconds: 100,
           moving_time_in_seconds: 100,
           distance_in_metres: 1_000,
           elevation_gain_in_metres: 100,
           activity_count: 1},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1},
             %Ranking{athlete_uuid: "athlete2", rank: 2}
           ]}
        ]
      )
    end
  end

  describe "assign activity to athlete from distance stage leaderboard with goal" do
    test "when leaderboard contains no entries" do
      assert_events(
        [
          {:challenge_leaderboard_created,
           challenge_type: "distance", rank_by: "goals", rank_order: "desc", has_goal?: true}
        ],
        {:assign_points_from_stage_leaderboard,
         stage_uuid: "stage1",
         challenge_stage_uuids: ["stage1", "stage2"],
         stage_type: "distance",
         entries: [
           %{
             rank: 1,
             athlete_uuid: "athlete1",
             elapsed_time_in_seconds: 200,
             moving_time_in_seconds: 200,
             distance_in_metres: 2_000,
             elevation_gain_in_metres: 200,
             goals: 1,
             goal_progress: Decimal.div(Decimal.new(2_000), Decimal.from_float(16.09)),
             stage_effort_count: 2
           },
           %{
             rank: 2,
             athlete_uuid: "athlete2",
             elapsed_time_in_seconds: 100,
             moving_time_in_seconds: 100,
             distance_in_metres: 1_000,
             elevation_gain_in_metres: 100,
             goals: 0,
             goal_progress: Decimal.div(Decimal.new(1_000), Decimal.from_float(16.09)),
             stage_effort_count: 1
           }
         ]},
        athlete_accumulated_activity_in_distance_challenge_leaderboard()
      )
    end

    test "when athlete achieves goal in all included stages" do
      assert_events(
        [
          {:challenge_leaderboard_created,
           challenge_type: "distance", rank_by: "goals", rank_order: "desc", has_goal?: true},
          athlete_accumulated_activity_in_distance_challenge_leaderboard()
        ],
        {:assign_points_from_stage_leaderboard,
         challenge_stage_uuids: ["stage1", "stage2"],
         stage_uuid: "stage2",
         stage_type: "distance",
         entries: [
           %{
             rank: 1,
             athlete_uuid: "athlete1",
             elapsed_time_in_seconds: 201,
             moving_time_in_seconds: 201,
             distance_in_metres: 2_001,
             elevation_gain_in_metres: 201,
             goals: 1,
             goal_progress: Decimal.div(Decimal.new(2_001), Decimal.from_float(16.09)),
             stage_effort_count: 2
           }
         ]},
        [
          {:athlete_accumulated_activity_in_challenge_leaderboard,
           stage_uuid: "stage2",
           challenge_type: "distance",
           athlete_uuid: "athlete1",
           elapsed_time_in_seconds: 201,
           moving_time_in_seconds: 201,
           distance_in_metres: 2_001,
           elevation_gain_in_metres: 201,
           goals: 1,
           goal_progress: Decimal.div(Decimal.new(2_001), Decimal.from_float(16.09)),
           activity_count: 2},
          :athlete_achieved_challenge_goal
        ]
      )
    end
  end

  describe "reconfigure point scoring" do
    test "should replace points" do
      assert_events(
        [
          :challenge_leaderboard_created
        ],
        {:reconfigure_challenge_leaderboard_points, points: [10, 8, 4, 2, 1]},
        [
          {:challenge_leaderboard_points_reconfigured, points: [10, 8, 4, 2, 1]}
        ]
      )
    end
  end

  test "should use replaced point scoring when assigning stage points" do
    assert_events(
      [
        :challenge_leaderboard_created,
        {:challenge_leaderboard_points_reconfigured, points: [10, 8, 4, 2, 1]}
      ],
      {:assign_points_from_stage_leaderboard,
       entries: [
         %{rank: 1, athlete_uuid: "athlete1"}
       ]},
      [
        {:athlete_accumulated_points_in_challenge_leaderboard,
         athlete_uuid: "athlete1", points: 10},
        {:challenge_leaderbord_ranked,
         new_entries: [
           %Ranking{athlete_uuid: "athlete1", rank: 1}
         ]}
      ]
    )
  end

  describe "adjust stage points after assignment" do
    test "should adjust existing points" do
      assert_events(
        [
          :challenge_leaderboard_created,
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete1", points: 15},
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete2", points: 12},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1},
             %Ranking{athlete_uuid: "athlete2", rank: 2}
           ]}
        ],
        # Swap athlete1 and athlete2 positions around
        {:adjust_points_from_stage_leaderboard,
         previous_entries: [
           %{rank: 1, athlete_uuid: "athlete1"},
           %{rank: 2, athlete_uuid: "athlete2"}
         ],
         adjusted_entries: [
           %{rank: 1, athlete_uuid: "athlete2"},
           %{rank: 2, athlete_uuid: "athlete1"}
         ]},
        [
          {:athlete_points_adjusted_in_challenge_leaderboard,
           athlete_uuid: "athlete1", points_adjustment: -15},
          {:athlete_points_adjusted_in_challenge_leaderboard,
           athlete_uuid: "athlete2", points_adjustment: -12},
          {:athlete_removed_from_challenge_leaderboard, athlete_uuid: "athlete1", rank: 1},
          {:athlete_removed_from_challenge_leaderboard, athlete_uuid: "athlete2", rank: 2},
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete2", points: 15},
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete1", points: 12},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete2", rank: 1},
             %Ranking{athlete_uuid: "athlete1", rank: 2}
           ]}
        ]
      )
    end
  end

  describe "adjust athlete's points" do
    test "should adjust existing points" do
      assert_events(
        [
          :challenge_leaderboard_created,
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete1", points: 15},
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete2", points: 12},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete1", rank: 1},
             %Ranking{athlete_uuid: "athlete2", rank: 2}
           ]}
        ],
        # Remove 5 points from athlete 1
        {:adjust_athlete_points_in_challenge_leaderboard,
         athlete_uuid: "athlete1", points_adjustment: -5},
        [
          {:athlete_points_adjusted_in_challenge_leaderboard,
           athlete_uuid: "athlete1", points_adjustment: -5},
          {:challenge_leaderbord_ranked,
           new_entries: [],
           positions_gained: [
             %Ranking{athlete_uuid: "athlete2", rank: 1, positions_changed: 1}
           ],
           positions_lost: [
             %Ranking{athlete_uuid: "athlete1", rank: 2, positions_changed: 1}
           ]}
        ]
      )
    end
  end

  describe "limit competitor point scoring and finalise leaderboard" do
    test "should be limited" do
      assert_events(
        [
          :challenge_leaderboard_created
        ],
        {:limit_competitor_point_scoring_in_challenge_leaderboard, athlete_uuid: "athlete1"},
        [
          {:competitor_scoring_in_challenge_leaderboard_limited, athlete_uuid: "athlete1"}
        ]
      )
    end

    test "should exclude competitor from accumulating points" do
      assert_events(
        [
          :challenge_leaderboard_created,
          {:competitor_scoring_in_challenge_leaderboard_limited, athlete_uuid: "athlete1"}
        ],
        {:assign_points_from_stage_leaderboard,
         entries: [
           %{rank: 1, athlete_uuid: "athlete1"},
           %{rank: 2, athlete_uuid: "athlete2"}
         ]},
        # Athlete1 won the stage, but isn't allowed to score points so athlete2 is ranked 1st.
        [
          {:athlete_accumulated_points_in_challenge_leaderboard,
           athlete_uuid: "athlete2", points: 15},
          {:challenge_leaderbord_ranked,
           new_entries: [
             %Ranking{athlete_uuid: "athlete2", rank: 1}
           ]}
        ]
      )
    end
  end

  defp athlete_accumulated_activity_in_distance_challenge_leaderboard do
    [
      {:athlete_accumulated_activity_in_challenge_leaderboard,
       stage_uuid: "stage1",
       challenge_type: "distance",
       athlete_uuid: "athlete1",
       elapsed_time_in_seconds: 200,
       moving_time_in_seconds: 200,
       distance_in_metres: 2_000,
       elevation_gain_in_metres: 200,
       goals: 1,
       goal_progress: Decimal.div(Decimal.new(2_000), Decimal.from_float(16.09)),
       activity_count: 2},
      {:athlete_accumulated_activity_in_challenge_leaderboard,
       stage_uuid: "stage1",
       challenge_type: "distance",
       athlete_uuid: "athlete2",
       elapsed_time_in_seconds: 100,
       moving_time_in_seconds: 100,
       distance_in_metres: 1_000,
       elevation_gain_in_metres: 100,
       goals: 0,
       goal_progress: Decimal.div(Decimal.new(1_000), Decimal.from_float(16.09)),
       activity_count: 1},
      {:challenge_leaderbord_ranked,
       has_goal?: true,
       new_entries: [
         %Ranking{athlete_uuid: "athlete1", rank: 1},
         %Ranking{athlete_uuid: "athlete2", rank: 2}
       ]}
    ]
  end
end
