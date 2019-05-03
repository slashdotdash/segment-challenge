defmodule SegmentChallenge.Notifications.HostChallenge do
  alias SegmentChallenge.Notifications.HostChallenge
  alias SegmentChallenge.Events.ChallengeCreated

  defstruct [:athlete_uuid, :name, :challenge_uuid, :url_slug]

  def new(%ChallengeCreated{} = event) do
    %ChallengeCreated{
      challenge_uuid: challenge_uuid,
      created_by_athlete_uuid: created_by_athlete_uuid,
      name: name,
      url_slug: url_slug
    } = event

    %HostChallenge{
      athlete_uuid: created_by_athlete_uuid,
      challenge_uuid: challenge_uuid,
      name: name,
      url_slug: url_slug
    }
  end
end
