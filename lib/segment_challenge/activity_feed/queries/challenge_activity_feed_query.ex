defmodule SegmentChallenge.Challenges.Queries.ActivityFeeds.ChallengeActivityFeedQuery do
  import Ecto.Query, only: [from: 2]
  alias SegmentChallenge.Projections.ActivityFeedProjection.ActivityProjection

  def new(challenge_uuid, stage_uuids) do
    from(a in ActivityProjection,
      where:
        (a.actor_type == "challenge" and a.actor_uuid == ^challenge_uuid) or
          (a.object_type == "challenge" and a.object_uuid == ^challenge_uuid) or
          (a.target_type == "challenge" and a.target_uuid == ^challenge_uuid) or
          (a.actor_type == "stage" and a.actor_uuid in ^stage_uuids) or
          (a.object_type == "stage" and a.object_uuid in ^stage_uuids),
      order_by: [desc: a.published, desc: a.id]
    )
  end
end
