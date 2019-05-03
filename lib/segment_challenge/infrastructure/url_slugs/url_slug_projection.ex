defmodule SegmentChallenge.Projections.Slugs.UrlSlugProjection do
  use Ecto.Schema

  schema "url_slugs" do
    field(:source, :string)
    field(:source_uuid, :string)
    field(:slug, :string)

    timestamps()
  end

  alias SegmentChallenge.Projections.Slugs.UrlSlugProjection

  defmodule Builder do
    use Commanded.Projections.Ecto, name: "UrlSlugProjection"

    alias SegmentChallenge.Events.ChallengeCancelled
    alias SegmentChallenge.Events.ChallengeCreated
    alias SegmentChallenge.Events.ChallengeRenamed
    alias SegmentChallenge.Events.StageCreated
    alias SegmentChallenge.Events.StageDeleted

    project %ChallengeCreated{challenge_uuid: challenge_uuid, url_slug: slug}, fn multi ->
      Ecto.Multi.insert(multi, :url_slug, %UrlSlugProjection{
        source: "challenge",
        source_uuid: challenge_uuid,
        slug: slug
      })
    end

    project %ChallengeRenamed{challenge_uuid: challenge_uuid, url_slug: slug}, fn multi ->
      Ecto.Multi.update_all(
        multi,
        :url_slug,
        slug_query("challenge", challenge_uuid),
        set: [
          slug: slug
        ]
      )
    end

    project %ChallengeCancelled{challenge_uuid: challenge_uuid}, fn multi ->
      Ecto.Multi.delete_all(multi, :url_slug, slug_query("challenge", challenge_uuid))
    end

    project %StageCreated{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid, url_slug: slug},
            fn multi ->
              Ecto.Multi.insert(multi, :url_slug, %UrlSlugProjection{
                source: challenge_uuid,
                source_uuid: stage_uuid,
                slug: slug
              })
            end

    project %StageDeleted{challenge_uuid: challenge_uuid, stage_uuid: stage_uuid}, fn multi ->
      Ecto.Multi.delete_all(multi, :url_slug, slug_query(challenge_uuid, stage_uuid))
    end

    defp slug_query(source, source_uuid) do
      from(u in UrlSlugProjection,
        where: u.source == ^source and u.source_uuid == ^source_uuid
      )
    end
  end
end
