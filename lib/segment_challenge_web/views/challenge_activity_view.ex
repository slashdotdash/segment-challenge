defmodule SegmentChallengeWeb.ChallengeActivityView do
  use SegmentChallengeWeb, :view

  def title("show.html", %{challenge: challenge}), do: challenge.name <> " activity - Segment Challenge"  
end
