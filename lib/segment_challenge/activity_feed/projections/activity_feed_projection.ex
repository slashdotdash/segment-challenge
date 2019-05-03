defmodule SegmentChallenge.Projections.ActivityFeedProjection do
  @moduledoc """
  An activity consists of an actor, a verb, an object, and a target.
  It tells the story of a person performing an action on or with an object."

  http://activitystrea.ms/specs/json/1.0/
  """

  defmodule ActorProjection do
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key {:actor_uuid, :string, []}

    schema "activity_feed_actors" do
      field(:actor_type, :string)
      field(:actor_name, :string)
      field(:actor_image, :string)

      timestamps()
    end

    def changeset(actor, params \\ %{}) do
      actor
      |> cast(params, [:actor_name, :actor_image])
    end
  end

  defmodule ActivityProjection do
    use Ecto.Schema

    schema "activity_feed_activities" do
      field(:published, :naive_datetime)
      field(:actor_type, :string)
      field(:actor_uuid, :string)
      field(:actor_name, :string)
      field(:actor_image, :string)
      field(:verb, :string)
      field(:object_type, :string)
      field(:object_uuid, :string)
      field(:object_name, :string)
      field(:object_image, :string)
      field(:target_type, :string)
      field(:target_uuid, :string)
      field(:target_name, :string)
      field(:target_image, :string)
      field(:message, :string)
      field(:metadata, :map)

      timestamps()
    end
  end
end
