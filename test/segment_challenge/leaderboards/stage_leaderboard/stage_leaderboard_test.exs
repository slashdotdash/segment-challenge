defmodule SegmentChallenge.Leaderboards.StageLeaderboardTest do
  use SegmentChallenge.AggregateCase, aggregate: SegmentChallenge.Leaderboards.StageLeaderboard

  alias SegmentChallenge.Events.StageLeaderboardRanked

  @moduletag :unit

  describe "segment stage leaderboard" do
    test "create segment stage leaderboard" do
      assert_events(
        :create_stage_leaderboard,
        [
          :stage_leaderboard_created
        ]
      )
    end
  end

  describe "distance stage leaderboard" do
    test "create distance stage leaderboard" do
      assert_events(
        {:create_stage_leaderboard,
         rank_by: "distance_in_metres",
         rank_order: "desc",
         accumulate_activities: true,
         has_goal: false},
        [
          distance_stage_leaderboard_created()
        ]
      )
    end

    test "create distance stage leaderboard with goal" do
      assert_events(
        {:create_stage_leaderboard,
         rank_by: "distance_in_metres",
         rank_order: "desc",
         accumulate_activities: true,
         has_goal: true,
         goal: 1.0,
         goal_units: "miles"},
        [
          distance_stage_leaderboard_with_goal_created()
        ]
      )
    end
  end

  describe "rank stage effort in segment stage leaderboard" do
    test "when leaderboard contains no entries" do
      assert_events(
        [
          :stage_leaderboard_created
        ],
        :rank_stage_efforts_in_stage_leaderboard,
        [
          :stage_leaderboard_ranked
        ]
      )
    end

    test "when leaderboard contains identical entries" do
      assert_events(
        [
          :stage_leaderboard_created,
          :stage_leaderboard_ranked
        ],
        :rank_stage_efforts_in_stage_leaderboard,
        []
      )
    end

    test "when athlete records a faster attempt" do
      assert_events(
        [
          :create_stage_leaderboard,
          :rank_stage_efforts_in_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165
             )
           ]}
        ],
        [
          :stage_leaderboard_created,
          :stage_leaderboard_ranked,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               stage_effort_count: 2
             )
           ],
           new_positions: []}
        ]
      )
    end

    test "when athlete records the same time" do
      assert_events(
        [
          :create_stage_leaderboard,
          :rank_stage_efforts_in_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               strava_segment_effort_id: 2
             )
           ]}
        ],
        [
          :stage_leaderboard_created,
          :stage_leaderboard_ranked,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort, stage_effort_count: 2)
           ],
           new_positions: []}
        ]
      )
    end

    test "when athlete records a slower time" do
      assert_events(
        [
          :create_stage_leaderboard,
          :rank_stage_efforts_in_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 195,
               moving_time_in_seconds: 195
             )
           ]}
        ],
        [
          :stage_leaderboard_created,
          :stage_leaderboard_ranked,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort, stage_effort_count: 2)
           ],
           new_positions: []}
        ]
      )
    end

    test "when athlete records a faster time than another athlete" do
      athlete1_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 1,
          strava_segment_effort_id: 1
        )

      athlete2_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete2",
          strava_activity_id: 2,
          strava_segment_effort_id: 2,
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165
        )

      assert_events(
        [
          :create_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [athlete1_effort]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [athlete1_effort, athlete2_effort]}
        ],
        segment_stage_leaderboard_created_with_two_athletes()
      )
    end

    test "when athlete records a slower time than another athlete" do
      assert_events(
        [
          :create_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort, athlete_uuid: "athlete1")
           ]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort, athlete_uuid: "athlete1"),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete2",
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 195,
               moving_time_in_seconds: 195
             )
           ]}
        ],
        [
          :stage_leaderboard_created,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort, athlete_uuid: "athlete1")
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ]},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort, athlete_uuid: "athlete1"),
             build(:stage_leaderboard_ranked_stage_effort,
               rank: 2,
               athlete_uuid: "athlete2",
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 195,
               moving_time_in_seconds: 195,
               stage_effort_count: 1
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete2",
               rank: 2,
               positions_changed: nil
             }
           ],
           positions_lost: []}
        ]
      )
    end

    test "when leaderboard contains slower entry for athlete and another athlete" do
      stage_effort1 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_segment_effort_id: 1,
          elapsed_time_in_seconds: 160,
          moving_time_in_seconds: 160
        )

      stage_effort2 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete2",
          strava_segment_effort_id: 2,
          elapsed_time_in_seconds: 170,
          moving_time_in_seconds: 170
        )

      stage_effort3 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete3",
          strava_segment_effort_id: 3,
          elapsed_time_in_seconds: 180,
          moving_time_in_seconds: 180
        )

      stage_effort4 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete3",
          strava_segment_effort_id: 4,
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165
        )

      assert_events(
        [
          :create_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [stage_effort1, stage_effort2, stage_effort3]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [stage_effort1, stage_effort2, stage_effort3, stage_effort4]}
        ],
        [
          :stage_leaderboard_created,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 160,
               moving_time_in_seconds: 160
             ),
             build(:stage_leaderboard_ranked_stage_effort,
               rank: 2,
               athlete_uuid: "athlete2",
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 170,
               moving_time_in_seconds: 170
             ),
             build(:stage_leaderboard_ranked_stage_effort,
               rank: 3,
               athlete_uuid: "athlete3",
               strava_segment_effort_id: 3,
               elapsed_time_in_seconds: 180,
               moving_time_in_seconds: 180
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             },
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete2",
               rank: 2,
               positions_changed: nil
             },
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete3",
               rank: 3,
               positions_changed: nil
             }
           ]},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 160,
               moving_time_in_seconds: 160
             ),
             build(:stage_leaderboard_ranked_stage_effort,
               rank: 2,
               athlete_uuid: "athlete3",
               strava_segment_effort_id: 4,
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               stage_effort_count: 2
             ),
             build(:stage_leaderboard_ranked_stage_effort,
               rank: 3,
               athlete_uuid: "athlete2",
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 170,
               moving_time_in_seconds: 170
             )
           ],
           new_positions: [],
           positions_gained: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete3",
               rank: 2,
               positions_changed: 1
             }
           ],
           positions_lost: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete2",
               rank: 3,
               positions_changed: 1
             }
           ]}
        ]
      )
    end
  end

  describe "rank stage effort in distance stage leaderboard" do
    test "when leaderboard contains no entries" do
      assert_events(
        [
          :create_distance_stage_leaderboard,
          :rank_stage_efforts_in_stage_leaderboard
        ],
        [
          distance_stage_leaderboard_created(),
          :stage_leaderboard_ranked
        ]
      )
    end

    test "when athlete ranked again should accumulate distance" do
      stage_effort1 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 1,
          strava_segment_effort_id: nil
        )

      stage_effort2 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 2,
          strava_segment_effort_id: nil,
          start_date: ~N[2016-01-26 12:48:14],
          start_date_local: ~N[2016-01-26 12:48:14],
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165
        )

      assert_events(
        [
          :create_distance_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [stage_effort1]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [stage_effort1, stage_effort2]}
        ],
        distance_stage_leaderboard_ranked_twice()
      )
    end

    test "when athlete ranked for a third time should accumulate distance" do
      stage_effort1 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 1,
          strava_segment_effort_id: nil
        )

      stage_effort2 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 2,
          strava_segment_effort_id: nil,
          start_date: ~N[2016-01-26 12:48:14],
          start_date_local: ~N[2016-01-26 12:48:14],
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165
        )

      stage_effort3 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 3,
          strava_segment_effort_id: nil,
          start_date: ~N[2016-01-27 12:48:14],
          start_date_local: ~N[2016-01-27 12:48:14],
          elapsed_time_in_seconds: 100,
          moving_time_in_seconds: 100
        )

      assert_events(
        distance_stage_leaderboard_ranked_twice(),
        {:rank_stage_efforts_in_stage_leaderboard,
         stage_efforts: [stage_effort1, stage_effort2, stage_effort3]},
        [
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 3,
               strava_segment_effort_id: nil,
               start_date: ~N[2016-01-27 12:48:14],
               start_date_local: ~N[2016-01-27 12:48:14],
               elapsed_time_in_seconds: 453,
               moving_time_in_seconds: 453,
               distance_in_metres: 1874.6 + 937.3,
               elevation_gain_in_metres: 204.0,
               stage_effort_count: 3
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []}
        ]
      )
    end

    test "reset stage leaderboard should clear all entries" do
      assert_events(
        [
          distance_stage_leaderboard_ranked_twice()
        ],
        :reset_stage_leaderboard,
        [
          :stage_leaderboard_cleared
        ]
      )
    end

    test "after stage leaderboard cleared should rank again" do
      assert_events(
        [
          distance_stage_leaderboard_ranked_twice(),
          :stage_leaderboard_cleared
        ],
        :rank_stage_efforts_in_stage_leaderboard,
        [
          :stage_leaderboard_ranked
        ]
      )
    end
  end

  describe "rank stage effort in distance stage leaderboard with goal" do
    test "when leaderboard contains no entries" do
      assert_events(
        [
          distance_stage_leaderboard_with_goal_created()
        ],
        {:rank_stage_efforts_in_stage_leaderboard,
         stage_efforts: [
           build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
             athlete_uuid: "athlete1"
           )
         ]},
        [
          {:stage_leaderboard_ranked,
           has_goal?: true,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               goal_progress: Decimal.div(Decimal.from_float(937.3), Decimal.from_float(16.09))
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ],
           positions_gained: [],
           positions_lost: []}
        ]
      )
    end

    test "should accumulate distance when athlete ranked again" do
      assert_events(
        [
          distance_stage_leaderboard_with_goal_created()
        ],
        [
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1"
             )
           ]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1"
             ),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               start_date: ~N[2016-01-27 12:48:14],
               start_date_local: ~N[2016-01-27 12:48:14],
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               distance_in_metres: 600.0
             )
           ]}
        ],
        [
          {:stage_leaderboard_ranked,
           has_goal?: true,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               goal_progress: Decimal.div(Decimal.from_float(937.3), Decimal.from_float(16.09))
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ],
           positions_gained: [],
           positions_lost: []},
          {:stage_leaderboard_ranked,
           has_goal?: true,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               start_date: ~N[2016-01-27 12:48:14],
               start_date_local: ~N[2016-01-27 12:48:14],
               elapsed_time_in_seconds: 353,
               moving_time_in_seconds: 353,
               distance_in_metres: 1537.3,
               elevation_gain_in_metres: 136.0,
               goal_progress: Decimal.div(Decimal.from_float(1537.3), Decimal.from_float(16.09)),
               stage_effort_count: 2
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []}
        ]
      )
    end

    test "should achieve goal once goal distance reached" do
      assert_events(
        [
          distance_stage_leaderboard_with_goal_created()
        ],
        [
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1"
             )
           ]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1"
             ),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               start_date: ~N[2016-01-27 12:48:14],
               start_date_local: ~N[2016-01-27 12:48:14],
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               distance_in_metres: 700.0
             )
           ]}
        ],
        [
          {:stage_leaderboard_ranked,
           has_goal?: true,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               goal_progress: Decimal.div(Decimal.from_float(937.3), Decimal.from_float(16.09))
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ],
           positions_gained: [],
           positions_lost: []},
          {:stage_leaderboard_ranked,
           has_goal?: true,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               start_date: ~N[2016-01-27 12:48:14],
               start_date_local: ~N[2016-01-27 12:48:14],
               elapsed_time_in_seconds: 353,
               moving_time_in_seconds: 353,
               distance_in_metres: 1637.3,
               elevation_gain_in_metres: 136.0,
               goal_progress: Decimal.div(Decimal.from_float(1637.3), Decimal.from_float(16.09)),
               stage_effort_count: 2
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []},
          {:athlete_achieved_stage_goal,
           athlete_uuid: "athlete1",
           stage_type: "mountain",
           goal: 1.0,
           goal_units: "miles",
           strava_activity_id: 2,
           strava_segment_effort_id: nil}
        ]
      )
    end
  end

  describe "remove stage effort from segment stage leaderboard" do
    test "should remove athlete's rank and re-rank leaderboard" do
      stage_effort1 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 1,
          strava_segment_effort_id: 1,
          elapsed_time_in_seconds: 172,
          moving_time_in_seconds: 172
        )

      stage_effort2 =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete2",
          strava_activity_id: 2,
          strava_segment_effort_id: 2,
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165
        )

      assert_events(
        [
          :create_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [stage_effort1]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [stage_effort1, stage_effort2]},
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [stage_effort1]}
        ],
        [
          :stage_leaderboard_created,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ]},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete2",
               strava_activity_id: 2,
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165
             ),
             build(:stage_leaderboard_ranked_stage_effort,
               rank: 2,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete2",
               rank: 1,
               positions_changed: nil
             }
           ],
           positions_gained: [],
           positions_lost: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 2,
               positions_changed: 1
             }
           ]},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: 1,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ],
           new_positions: [],
           positions_gained: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: 1
             }
           ],
           positions_lost: []}
        ]
      )
    end

    test "should replace with athlete's earlier slower stage effort" do
      earlier_stage_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 1,
          strava_segment_effort_id: 1,
          start_date: ~N[2016-01-24 12:48:14],
          start_date_local: ~N[2016-01-24 12:48:14],
          elapsed_time_in_seconds: 172,
          moving_time_in_seconds: 172
        )

      later_stage_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 2,
          strava_segment_effort_id: 2,
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165
        )

      assert_events(
        [
          :create_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [earlier_stage_effort]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [earlier_stage_effort, later_stage_effort]},
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [earlier_stage_effort]}
        ],
        [
          :stage_leaderboard_created,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: 1,
               start_date: ~N[2016-01-24 12:48:14],
               start_date_local: ~N[2016-01-24 12:48:14],
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ]},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               stage_effort_count: 2
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: 1,
               start_date: ~N[2016-01-24 12:48:14],
               start_date_local: ~N[2016-01-24 12:48:14],
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []}
        ]
      )
    end

    test "should replace with athlete's later slower stage effort" do
      earlier_stage_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 1,
          strava_segment_effort_id: 1,
          start_date: ~N[2016-01-24 12:48:14],
          start_date_local: ~N[2016-01-24 12:48:14],
          elapsed_time_in_seconds: 165,
          moving_time_in_seconds: 165
        )

      later_stage_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 2,
          strava_segment_effort_id: 2,
          elapsed_time_in_seconds: 172,
          moving_time_in_seconds: 172
        )

      assert_events(
        [
          :create_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [earlier_stage_effort]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [earlier_stage_effort, later_stage_effort]},
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [later_stage_effort]}
        ],
        [
          :stage_leaderboard_created,
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: 1,
               start_date: ~N[2016-01-24 12:48:14],
               start_date_local: ~N[2016-01-24 12:48:14],
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ]},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: 1,
               start_date: ~N[2016-01-24 12:48:14],
               start_date_local: ~N[2016-01-24 12:48:14],
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               stage_effort_count: 2
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: 2,
               elapsed_time_in_seconds: 172,
               moving_time_in_seconds: 172,
               stage_effort_count: 1
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []}
        ]
      )
    end
  end

  describe "remove stage effort from distance stage leaderboard" do
    test "should replace attempt with shorter distance effort" do
      earlier_stage_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 1,
          strava_segment_effort_id: nil,
          start_date: ~N[2016-01-24 12:48:14],
          start_date_local: ~N[2016-01-24 12:48:14],
          elapsed_time_in_seconds: 100,
          moving_time_in_seconds: 100,
          distance_in_metres: 1_000.0,
          elevation_gain_in_metres: 10.0
        )

      later_stage_effort =
        build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
          athlete_uuid: "athlete1",
          strava_activity_id: 2,
          strava_segment_effort_id: nil,
          elapsed_time_in_seconds: 200,
          moving_time_in_seconds: 200,
          distance_in_metres: 2_000.0,
          elevation_gain_in_metres: 20.0
        )

      assert_events(
        [
          :create_distance_stage_leaderboard,
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [earlier_stage_effort]},
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [earlier_stage_effort, later_stage_effort]},
          {:rank_stage_efforts_in_stage_leaderboard, stage_efforts: [later_stage_effort]}
        ],
        [
          distance_stage_leaderboard_created(),
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: nil,
               start_date: ~N[2016-01-24 12:48:14],
               start_date_local: ~N[2016-01-24 12:48:14],
               elapsed_time_in_seconds: 100,
               moving_time_in_seconds: 100,
               distance_in_metres: 1_000.0,
               elevation_gain_in_metres: 10.0
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 1,
               positions_changed: nil
             }
           ]},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               elapsed_time_in_seconds: 300,
               moving_time_in_seconds: 300,
               distance_in_metres: 3_000.0,
               elevation_gain_in_metres: 30.0,
               stage_effort_count: 2
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []},
          {:stage_leaderboard_ranked,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               elapsed_time_in_seconds: 200,
               moving_time_in_seconds: 200,
               distance_in_metres: 2_000.0,
               elevation_gain_in_metres: 20.0
             )
           ],
           new_positions: [],
           positions_gained: [],
           positions_lost: []}
        ]
      )
    end
  end

  describe "finalise segment stage leaderboard" do
    test "should create final entries" do
      assert_events(
        segment_stage_leaderboard_created_with_two_athletes(),
        :finalise_stage_leaderboard,
        [
          {:stage_leaderboard_finalised,
           entries: [
             %{
               rank: 1,
               athlete_uuid: "athlete2",
               elapsed_time_in_seconds: 165,
               moving_time_in_seconds: 165,
               distance_in_metres: 937.3,
               elevation_gain_in_metres: 68.0,
               stage_effort_count: 1
             },
             %{
               rank: 2,
               athlete_uuid: "athlete1",
               elapsed_time_in_seconds: 188,
               moving_time_in_seconds: 188,
               distance_in_metres: 937.3,
               elevation_gain_in_metres: 68.0,
               stage_effort_count: 1
             }
           ]}
        ]
      )
    end
  end

  describe "finalise distance stage leaderboard" do
    test "should create final entries" do
      assert_events(
        distance_stage_leaderboard_created_with_two_athlete_ranked_efforts(),
        :finalise_stage_leaderboard,
        [
          {:stage_leaderboard_finalised,
           entries: [
             %{
               rank: 1,
               athlete_uuid: "athlete2",
               elapsed_time_in_seconds: 188,
               moving_time_in_seconds: 188,
               distance_in_metres: 2_000.0,
               elevation_gain_in_metres: 68.0,
               stage_effort_count: 1
             },
             %{
               rank: 2,
               athlete_uuid: "athlete1",
               elapsed_time_in_seconds: 188,
               moving_time_in_seconds: 188,
               distance_in_metres: 1_000.0,
               elevation_gain_in_metres: 68.0,
               stage_effort_count: 1
             }
           ]}
        ]
      )
    end
  end

  describe "finalise distance stage leaderboard with goal" do
    test "should create final entries including goal and progress" do
      assert_events(
        distance_stage_leaderboard_with_goal_created(),
        [
          {:rank_stage_efforts_in_stage_leaderboard,
           stage_efforts: [
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: nil,
               elapsed_time_in_seconds: 100,
               moving_time_in_seconds: 100,
               distance_in_metres: 1_000.0,
               elevation_gain_in_metres: 10.0
             ),
             build(:rank_stage_efforts_in_stage_leaderboard_stage_effort,
               athlete_uuid: "athlete2",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               elapsed_time_in_seconds: 200,
               moving_time_in_seconds: 200,
               distance_in_metres: 2_000.0,
               elevation_gain_in_metres: 20.0
             )
           ]},
          :finalise_stage_leaderboard
        ],
        [
          {:stage_leaderboard_ranked,
           has_goal?: true,
           stage_efforts: [
             build(:stage_leaderboard_ranked_stage_effort,
               athlete_uuid: "athlete2",
               strava_activity_id: 2,
               strava_segment_effort_id: nil,
               elapsed_time_in_seconds: 200,
               moving_time_in_seconds: 200,
               distance_in_metres: 2_000.0,
               elevation_gain_in_metres: 20.0,
               goal_progress: Decimal.div(Decimal.new(2_000), Decimal.from_float(16.09))
             ),
             build(:stage_leaderboard_ranked_stage_effort,
               rank: 2,
               athlete_uuid: "athlete1",
               strava_activity_id: 1,
               strava_segment_effort_id: nil,
               elapsed_time_in_seconds: 100,
               moving_time_in_seconds: 100,
               distance_in_metres: 1_000.0,
               elevation_gain_in_metres: 10.0,
               goal_progress: Decimal.div(Decimal.new(1_000), Decimal.from_float(16.09))
             )
           ],
           new_positions: [
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete2",
               rank: 1,
               positions_changed: nil
             },
             %StageLeaderboardRanked.Ranking{
               athlete_uuid: "athlete1",
               rank: 2,
               positions_changed: nil
             }
           ],
           positions_gained: [],
           positions_lost: []},
          {:athlete_achieved_stage_goal,
           athlete_uuid: "athlete2",
           stage_type: "mountain",
           goal: 1.0,
           goal_units: "miles",
           strava_activity_id: 2,
           strava_segment_effort_id: nil},
          {:stage_leaderboard_finalised,
           has_goal?: true,
           entries: [
             %{
               rank: 1,
               athlete_uuid: "athlete2",
               elapsed_time_in_seconds: 200,
               moving_time_in_seconds: 200,
               distance_in_metres: 2_000.0,
               elevation_gain_in_metres: 20.0,
               goals: 1,
               goal_progress: Decimal.div(Decimal.new(2_000), Decimal.from_float(16.09)),
               stage_effort_count: 1
             },
             %{
               rank: 2,
               athlete_uuid: "athlete1",
               elapsed_time_in_seconds: 100,
               moving_time_in_seconds: 100,
               distance_in_metres: 1_000.0,
               elevation_gain_in_metres: 10.0,
               goals: 0,
               goal_progress: Decimal.div(Decimal.new(1_000), Decimal.from_float(16.09)),
               stage_effort_count: 1
             }
           ]}
        ]
      )
    end
  end

  defp distance_stage_leaderboard_created do
    {:stage_leaderboard_created,
     rank_by: "distance_in_metres",
     rank_order: "desc",
     accumulate_activities?: true,
     has_goal?: false}
  end

  defp distance_stage_leaderboard_with_goal_created do
    {:stage_leaderboard_created,
     rank_by: "distance_in_metres",
     rank_order: "desc",
     accumulate_activities?: true,
     has_goal?: true,
     goal: 1.0,
     goal_units: "miles"}
  end

  defp segment_stage_leaderboard_created_with_two_athletes do
    [
      :stage_leaderboard_created,
      {:stage_leaderboard_ranked,
       stage_efforts: [
         build(:stage_leaderboard_ranked_stage_effort,
           athlete_uuid: "athlete1",
           strava_activity_id: 1,
           strava_segment_effort_id: 1
         )
       ],
       new_positions: [
         %StageLeaderboardRanked.Ranking{
           athlete_uuid: "athlete1",
           rank: 1,
           positions_changed: nil
         }
       ]},
      {:stage_leaderboard_ranked,
       stage_efforts: [
         build(:stage_leaderboard_ranked_stage_effort,
           athlete_uuid: "athlete2",
           strava_activity_id: 2,
           strava_segment_effort_id: 2,
           elapsed_time_in_seconds: 165,
           moving_time_in_seconds: 165,
           stage_effort_count: 1
         ),
         build(:stage_leaderboard_ranked_stage_effort,
           rank: 2,
           athlete_uuid: "athlete1",
           strava_activity_id: 1,
           strava_segment_effort_id: 1
         )
       ],
       new_positions: [
         %StageLeaderboardRanked.Ranking{
           athlete_uuid: "athlete2",
           rank: 1,
           positions_changed: nil
         }
       ],
       positions_lost: [
         %StageLeaderboardRanked.Ranking{
           athlete_uuid: "athlete1",
           rank: 2,
           positions_changed: 1
         }
       ]}
    ]
  end

  defp distance_stage_leaderboard_created_with_two_athlete_ranked_efforts do
    [
      {:stage_leaderboard_created,
       rank_by: "distance_in_metres",
       rank_order: "desc",
       accumulate_activities?: true,
       has_goal?: false},
      {:stage_leaderboard_ranked,
       stage_efforts: [
         build(:stage_leaderboard_ranked_stage_effort,
           athlete_uuid: "athlete1",
           strava_activity_id: 1,
           strava_segment_effort_id: nil,
           distance_in_metres: 1_000.0
         )
       ],
       new_positions: [
         %StageLeaderboardRanked.Ranking{
           athlete_uuid: "athlete1",
           rank: 1,
           positions_changed: nil
         }
       ]},
      {:stage_leaderboard_ranked,
       stage_efforts: [
         build(:stage_leaderboard_ranked_stage_effort,
           athlete_uuid: "athlete2",
           strava_activity_id: 2,
           strava_segment_effort_id: nil,
           distance_in_metres: 2_000.0
         ),
         build(:stage_leaderboard_ranked_stage_effort,
           rank: 2,
           athlete_uuid: "athlete1",
           strava_activity_id: 1,
           strava_segment_effort_id: nil,
           distance_in_metres: 1_000.0
         )
       ],
       new_positions: [
         %StageLeaderboardRanked.Ranking{
           athlete_uuid: "athlete2",
           rank: 1,
           positions_changed: nil
         }
       ],
       positions_gained: [],
       positions_lost: [
         %StageLeaderboardRanked.Ranking{
           athlete_uuid: "athlete1",
           rank: 2,
           positions_changed: 1
         }
       ]}
    ]
  end

  defp distance_stage_leaderboard_ranked_twice do
    [
      distance_stage_leaderboard_created(),
      {:stage_leaderboard_ranked,
       stage_efforts: [
         build(:stage_leaderboard_ranked_stage_effort,
           athlete_uuid: "athlete1",
           strava_activity_id: 1,
           strava_segment_effort_id: nil
         )
       ],
       new_positions: [
         %StageLeaderboardRanked.Ranking{
           athlete_uuid: "athlete1",
           rank: 1,
           positions_changed: nil
         }
       ]},
      {:stage_leaderboard_ranked,
       stage_efforts: [
         build(:stage_leaderboard_ranked_stage_effort,
           athlete_uuid: "athlete1",
           strava_activity_id: 2,
           strava_segment_effort_id: nil,
           start_date: ~N[2016-01-26 12:48:14],
           start_date_local: ~N[2016-01-26 12:48:14],
           elapsed_time_in_seconds: 353,
           moving_time_in_seconds: 353,
           distance_in_metres: 1874.6,
           elevation_gain_in_metres: 136.0,
           stage_effort_count: 2
         )
       ],
       new_positions: [],
       positions_gained: [],
       positions_lost: []}
    ]
  end
end
