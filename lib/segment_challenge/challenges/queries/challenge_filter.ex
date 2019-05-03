defmodule SegmentChallenge.Challenges.Queries.Challenges.ChallengeFilter do
  import Ecto.Query

  def by_type(query, nil), do: query

  def by_type(query, type) do
    from(c in query, where: c.challenge_type == ^type)
  end

  def by_activity(query, nil), do: query

  def by_activity(query, activity_type) do
    from(c in query, where: fragment("? @> ?", c.included_activity_types, [^activity_type]))
  end
end
