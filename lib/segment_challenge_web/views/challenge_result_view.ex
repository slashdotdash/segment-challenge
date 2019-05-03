defmodule SegmentChallengeWeb.ChallengeResultView do
  use SegmentChallengeWeb, :view

  import SegmentChallengeWeb.Helpers.LeaderboardHelpers

  def title("show.html", %{challenge: challenge}),
    do: challenge.name <> " results - Segment Challenge"

  def render("scripts.publish.html", %{challenge: challenge}) do
    """
    <script type="text/javascript">
    SegmentChallenge.renderMarkdownEditor('challenge-results-markdown', {
      label: 'Provide a summary of the challenge',
      name: 'message',
      markdown: `#{String.replace(challenge.results_markdown || "", "`", "\\`")}`,
      rowCount: 15
    })
    </script>)
    """
    |> raw()
  end
end
