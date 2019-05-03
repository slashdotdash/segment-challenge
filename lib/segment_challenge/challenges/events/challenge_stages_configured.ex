defmodule SegmentChallenge.Events.ChallengeStagesConfigured do
  @moduledoc """
  Challenge has been configured with stages for its entire duration (from start to end dates).
  """
  @derive Jason.Encoder
  defstruct [
    :challenge_uuid,
    stage_uuids: []
  ]
end
