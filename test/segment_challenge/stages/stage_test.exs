defmodule SegmentChallenge.Stages.StageTest do
  use SegmentChallenge.AggregateCase, aggregate: SegmentChallenge.Stages.Stage
  use SegmentChallenge.Stages.Stage.Aliases

  @moduletag :unit

  describe "segment stage" do
    test "create segment stage" do
      assert_events(
        :create_segment_stage,
        segment_stage_created()
      )
    end

    test "import stage efforts should record efforts for stage competitors" do
      assert_events(
        [
          segment_stage_created(),
          :stage_started,
          :competitors_joined_stage
        ],
        :import_stage_efforts,
        [
          :stage_effort_recorded
        ]
      )
    end

    test "should allow private stage efforts if configured" do
      assert_events(
        [
          segment_stage_created(allow_private_activities?: true),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(private?: true),
        [
          {:stage_effort_recorded, private?: true}
        ]
      )
    end
  end

  describe "distance stage" do
    test "create distance stage" do
      assert_events(
        :create_distance_stage,
        [
          distance_stage_created(),
          :stage_goal_configured
        ]
      )
    end

    test "should include swim trainer activity when swim activities included" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["Swim"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "Swim", trainer?: true),
        [
          {:stage_effort_recorded, stage_type: "distance", activity_type: "Swim", trainer?: true}
        ]
      )
    end

    test "should exclude swim trainer activity when swim activities excluded" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["Run"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "Swim", trainer?: true),
        []
      )
    end

    test "should exclude trainer run activity when virtual run activities excluded" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["Run"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "Run", trainer?: true),
        []
      )
    end

    test "should include trainer run activity when virtual run activities included" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["VirtualRun"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "Run", trainer?: true),
        [
          {:stage_effort_recorded, stage_type: "distance", activity_type: "Run", trainer?: true}
        ]
      )
    end

    test "should include trainer virtual run activity when virtual run activities included" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["VirtualRun"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "VirtualRun", trainer?: true),
        [
          {:stage_effort_recorded,
           stage_type: "distance", activity_type: "VirtualRun", trainer?: true}
        ]
      )
    end

    test "should exclude trainer ride activity when virtual ride activities excluded" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["Ride"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "Ride", trainer?: true),
        []
      )
    end

    test "should include trainer ride activity when virtual ride activities included" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["VirtualRide"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "Ride", trainer?: true),
        [
          {:stage_effort_recorded, stage_type: "distance", activity_type: "Ride", trainer?: true}
        ]
      )
    end

    test "should include trainer virtual ride activity when virtual ride activities included" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["VirtualRide"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "VirtualRide", trainer?: true),
        [
          {:stage_effort_recorded,
           stage_type: "distance", activity_type: "VirtualRide", trainer?: true}
        ]
      )
    end

    test "should include trainer rowing activity when rowing activities included" do
      assert_events(
        [
          distance_stage_created(included_activity_types: ["Rowing"]),
          :stage_started,
          :competitors_joined_stage
        ],
        import_stage_effort(activity_type: "Rowing", trainer?: true),
        [
          {:stage_effort_recorded,
           stage_type: "distance", activity_type: "Rowing", trainer?: true}
        ]
      )
    end
  end

  test "start a stage" do
    assert_events(
      segment_stage_created(),
      :start_stage,
      [
        :stage_started,
        {:stage_leaderboard_requested, name: "Men", gender: "M"},
        {:stage_leaderboard_requested, name: "Women", gender: "F"}
      ]
    )
  end

  describe "remove competitor from stage" do
    test "should be removed" do
      assert_events(
        [
          segment_stage_created(),
          :stage_started,
          :competitors_joined_stage
        ],
        :remove_competitor_from_stage,
        [
          {:competitor_removed_from_stage, attempt_count: 0}
        ]
      )
    end

    test "should allow removed competitor to rejoin" do
      assert_events(
        [
          segment_stage_created(),
          :stage_started,
          :competitors_joined_stage,
          {:stage_effort_recorded, stage_type: "distance", activity_type: "Swim", trainer?: true},
          :competitor_removed_from_stage
        ],
        :include_competitors_in_stage,
        [
          :competitors_joined_stage
        ]
      )
    end

    test "should record removed competitor's attempts'" do
      assert_events(
        [
          segment_stage_created(),
          :stage_started,
          :competitors_joined_stage,
          :stage_effort_recorded,
          :competitor_removed_from_stage,
          :competitors_joined_stage
        ],
        :import_stage_efforts,
        [
          :stage_effort_recorded
        ]
      )
    end
  end

  describe "configure athlete gender" do
    test "should amend gender and remove athlete's stage efforts" do
      assert_events(
        [
          {:stage_created, url_slug: "vcv-sleepers-hill"},
          :stage_segment_configured,
          :stage_started,
          {:competitors_joined_stage,
           competitors: [
             %CompetitorsJoinedStage.Competitor{
               athlete_uuid: "athlete-5704447",
               gender: nil
             }
           ]},
          {:stage_effort_recorded, athlete_gender: nil}
        ],
        {:configure_athlete_gender_in_stage, gender: "M"},
        [
          :stage_effort_removed,
          :athlete_gender_amended_in_stage
        ]
      )
    end

    test "should not affect other competitors stage efforts" do
      assert_events(
        [
          distance_stage_created(),
          :stage_started,
          {:competitors_joined_stage,
           competitors: [
             %CompetitorsJoinedStage.Competitor{
               athlete_uuid: "athlete1",
               gender: nil
             },
             %CompetitorsJoinedStage.Competitor{
               athlete_uuid: "athlete2",
               gender: "M"
             }
           ]},
          {:stage_effort_recorded,
           stage_type: "distance",
           athlete_uuid: "athlete1",
           athlete_gender: nil,
           strava_activity_id: 1,
           strava_segment_effort_id: nil,
           competitor_count: 1},
          {:stage_effort_recorded,
           stage_type: "distance",
           athlete_uuid: "athlete2",
           athlete_gender: "M",
           strava_activity_id: 2,
           strava_segment_effort_id: nil,
           competitor_count: 2},
          {:stage_effort_removed,
           athlete_uuid: "athlete1",
           strava_activity_id: 1,
           strava_segment_effort_id: nil,
           attempt_count: 0,
           competitor_count: 1},
          {:athlete_gender_amended_in_stage, athlete_uuid: "athlete1"}
        ],
        {:import_stage_efforts,
         stage_efforts: [
           build(:import_stage_efforts_stage_effort,
             athlete_uuid: "athlete1",
             strava_activity_id: 1,
             strava_segment_effort_id: nil
           ),
           build(:import_stage_efforts_stage_effort,
             athlete_uuid: "athlete2",
             strava_activity_id: 2,
             strava_segment_effort_id: nil
           )
         ]},
        [
          {:stage_effort_recorded,
           stage_type: "distance",
           athlete_uuid: "athlete1",
           athlete_gender: "M",
           strava_activity_id: 1,
           strava_segment_effort_id: nil,
           competitor_count: 2}
        ]
      )
    end
  end

  describe "remove stage activity" do
    test "should remove athlete's stage efforts" do
      assert_events(
        [
          :stage_created,
          :stage_segment_configured,
          :stage_started,
          :competitors_joined_stage,
          {:stage_effort_recorded,
           strava_activity_id: 1, strava_segment_effort_id: 1, attempt_count: 1},
          {:stage_effort_recorded,
           strava_activity_id: 1, strava_segment_effort_id: 2, attempt_count: 2},
          {:stage_effort_recorded,
           strava_activity_id: 2, strava_segment_effort_id: 3, attempt_count: 3},
          {:stage_effort_recorded,
           strava_activity_id: 3, strava_segment_effort_id: 4, attempt_count: 4}
        ],
        {:remove_stage_activity, strava_activity_id: 1},
        [
          {:stage_effort_removed,
           strava_activity_id: 1,
           strava_segment_effort_id: 2,
           attempt_count: 3,
           competitor_count: 1},
          {:stage_effort_removed,
           strava_activity_id: 1,
           strava_segment_effort_id: 1,
           attempt_count: 2,
           competitor_count: 1}
        ]
      )
    end
  end

  defp import_stage_effort(attrs) do
    {:import_stage_efforts,
     stage_efforts: [
       build(:import_stage_efforts_stage_effort, attrs)
     ]}
  end

  def segment_stage_created(attrs \\ []) do
    [
      {:stage_created, attrs},
      {:stage_segment_configured, distance_in_metres: 908.2, strava_segment_id: 8_622_812}
    ]
  end

  def distance_stage_created(attrs \\ []) do
    {:stage_created,
     Keyword.merge(
       [
         stage_type: "distance",
         name: "December Cycling Distance Challenge",
         description: "Can you ride 1,000 miles in October 2018?",
         start_date: ~N[2018-10-01 01:00:00],
         start_date_local: ~N[2018-10-01 00:00:00],
         end_date: ~N[2018-10-31 23:59:59],
         end_date_local: ~N[2018-10-31 23:59:59],
         url_slug: "december-cycling-distance-challenge",
         visible?: true
       ],
       attrs
     )}
  end
end
