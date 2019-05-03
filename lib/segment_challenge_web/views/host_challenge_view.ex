defmodule SegmentChallengeWeb.HostChallengeView do
  use SegmentChallengeWeb, :view

  def title("index.html", _assigns), do: "Host your own challenge - Segment Challenge"
  def title("new.html", _assigns), do: "Create your challenge - Segment Challenge"

  def render("scripts.new.html", assigns) do
    %{challenge_type: challenge_type, redirect_to: redirect_to} = assigns

    """
    <script>
    SegmentChallenge.renderCreateChallenge('createChallenge', {
      challengeType: '#{challenge_type}',
      redirectTo: '#{redirect_to}'
    })
    </script>
    """
    |> raw
  end
end
