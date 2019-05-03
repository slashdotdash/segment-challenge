defmodule SegmentChallenge.Commands.RenameChallenge do
  alias SegmentChallenge.Challenges.Services.UrlSlugs.UniqueSlugger

  defstruct [
    :challenge_uuid,
    :name,
    :renamed_by_athlete_uuid,
    slugger: &UniqueSlugger.slugify/3
  ]

  use ExConstructor
  use Vex.Struct

  validates(:challenge_uuid, uuid: true)
  validates(:name, presence: true, string: true)
  validates(:renamed_by_athlete_uuid, uuid: true)
end
