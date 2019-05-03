defmodule SegmentChallengeWeb.ChallengeStageView do
  use SegmentChallengeWeb, :view

  import SegmentChallengeWeb.Helpers.ChallengeHelpers

  def title("show.html", %{challenge: challenge}), do: challenge.name <> " stages - Segment Challenge"
end
