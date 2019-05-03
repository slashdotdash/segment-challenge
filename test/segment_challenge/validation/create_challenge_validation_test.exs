defmodule SegmentChallenge.Commands.Validation.CreateChallengeValidationTest do
  use ExUnit.Case

  alias SegmentChallenge.Commands.CreateChallenge

  test "should be invalid when empty" do
    assert Vex.valid?(%CreateChallenge{}) == false
  end

  test "should provide errors when empty" do
    errors = Vex.errors(%CreateChallenge{})
    assert length(errors) > 0
  end

  test "should be valid when filled" do
    now = NaiveDateTime.utc_now()

    command = %CreateChallenge{
      challenge_uuid: UUID.uuid4(),
      challenge_type: "segment",
      name: "VC Venta Segment of the Month 2016",
      description: """
      A friendly competition open to VC Venta members.
      Each month the organiser will nominate a Strava segment.
      Whoever records the fastest time (male and female) over the segment is the winner.

      Placings contribute to the overall competitions.
      """,
      start_date: Timex.beginning_of_month(now),
      start_date_local: Timex.beginning_of_month(now),
      end_date: Timex.end_of_month(now),
      end_date_local: Timex.end_of_month(now),
      restricted_to_club_members: true,
      allow_private_activities: false,
      hosted_by_club_uuid: "club-7289",
      hosted_by_club_name: "VC Venta",
      created_by_athlete_uuid: "athlete-5704447",
      created_by_athlete_name: "Ben Smith"
    }

    assert Vex.valid?(command)
  end
end
