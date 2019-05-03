defmodule SegmentChallengeWeb.Helpers.LeaderboardHelpers do
  alias SegmentChallenge.Leaderboards.StageLeaderboard.StageLeaderboardProjection
  alias SegmentChallengeWeb.StageLeaderboardView

  def render_stage_leaderboard(%StageLeaderboardProjection{} = leaderboard, options) do
    %StageLeaderboardProjection{stage_type: stage_type} = leaderboard

    template =
      case stage_type do
        activity when activity in ["activity", "distance", "duration", "elevation"] ->
          "activity_leaderboard.html"

        "race" ->
          "race_leaderboard.html"

        segment when segment in ["segment", "mountain", "rolling", "flat"] ->
          "segment_leaderboard.html"
      end

    Phoenix.View.render(
      StageLeaderboardView,
      template,
      Keyword.put(options, :leaderboard, leaderboard)
    )
  end

  def activity_description("VirtualRide"), do: "Virtual Ride"
  def activity_description("VirtualRun"), do: "Virtual Run"
  def activity_description(activity_type), do: activity_type
end
