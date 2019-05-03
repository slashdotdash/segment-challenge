defmodule SegmentChallenge.Leaderboards.ChallengeLeaderboard.LeaderboardEntry do
  alias SegmentChallenge.Leaderboards.ChallengeLeaderboard.LeaderboardEntry

  @derive Jason.Encoder
  defstruct [
    :rank,
    :points,
    :elapsed_time_in_seconds,
    :moving_time_in_seconds,
    :distance_in_metres,
    :elevation_gain_in_metres,
    :goals,
    :athlete_uuid,
    :gender,
    stage_goals: MapSet.new()
  ]

  def adjust(%LeaderboardEntry{} = entry, _field, nil), do: entry

  def adjust(%LeaderboardEntry{} = entry, field, adjustment) when is_number(adjustment) do
    Map.update(entry, field, adjustment, fn existing -> existing + adjustment end)
  end

  def record_stage_goal(%LeaderboardEntry{} = entry, 0, _stage_uuid), do: entry

  def record_stage_goal(%LeaderboardEntry{} = entry, goals, stage_uuid) when goals > 0 do
    %LeaderboardEntry{stage_goals: stage_goals} = entry

    %LeaderboardEntry{entry | stage_goals: MapSet.put(stage_goals, stage_uuid)}
  end

  @doc """
  Has the goal been achieved for each stage?
  """
  def achieved_goal?(%LeaderboardEntry{} = entry, %MapSet{} = stage_uuids) do
    %LeaderboardEntry{stage_goals: stage_goals} = entry

    MapSet.subset?(stage_uuids, stage_goals)
  end
end
