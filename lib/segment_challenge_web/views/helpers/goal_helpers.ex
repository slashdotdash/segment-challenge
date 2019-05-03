defmodule SegmentChallengeWeb.Helpers.GoalHelpers do
  def display_goal(goal) when is_integer(goal), do: goal

  def display_goal(goal) when is_float(goal) do
    case Float.round(goal) do
      ^goal -> trunc(goal)
      _ -> goal
    end
  end

  def goal_recurrence("none"), do: ""
  def goal_recurrence("day"), do: "/ day"
  def goal_recurrence("week"), do: "/ week"
  def goal_recurrence("month"), do: "/ month"
end
