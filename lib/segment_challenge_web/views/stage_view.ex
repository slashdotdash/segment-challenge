defmodule SegmentChallengeWeb.StageView do
  use SegmentChallengeWeb, :view

  import SegmentChallengeWeb.Helpers.ChallengeHelpers
  import SegmentChallengeWeb.Helpers.StageHelpers

  def title("show.html", %{stage: stage}), do: stage.name <> " - Segment Challenge"
  def title("new.html", _), do: "Create a stage - Segment Challenge"

  def render("scripts.show.html", %{stage: %{map_polyline: nil}}), do: ""

  def render("scripts.show.html", %{stage: stage}) do
    """
    <script>
    SegmentChallenge.renderMap('map', {
      start: [#{stage.start_latitude},#{stage.start_longitude}],
      end: [#{stage.end_latitude},#{stage.end_longitude}],
      polyline: '#{String.replace(stage.map_polyline, "\\", "\\\\")}'
    })
    </script>
    """
    |> raw
  end

  def render("scripts.new.html", assigns) do
    %{challenge: challenge, create_stage: create_stage, redirect_to: redirect_to} = assigns

    """
    <script>
    SegmentChallenge.renderCreateStage('createStage', {
      challengeUUID: '#{create_stage.challenge_uuid}',
      stageType: '#{challenge.challenge_type}',
      stageNumber: #{create_stage.stage_number},
      allowPrivateActivities: #{challenge.allow_private_activities},
      minStartDate: '#{NaiveDateTime.to_iso8601(create_stage.start_date)}Z',
      maxEndDate: '#{NaiveDateTime.to_iso8601(create_stage.end_date)}Z',
      redirectTo: '#{redirect_to}'
    })
    </script>
    """
    |> raw
  end

  def render("scripts.edit.html", %{stage: stage}) do
    """
    <script type="text/javascript">
    SegmentChallenge.renderMarkdownEditor('stage_description_markdown', {
      label: 'Describe the stage',
      name: 'description',
      markdown: `#{String.replace(stage.description_markdown || "", "`", "\\`")}`,
      rowCount: 15
    })
    </script>)
    """
    |> raw
  end
end
