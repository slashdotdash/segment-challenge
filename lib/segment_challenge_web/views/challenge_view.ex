defmodule SegmentChallengeWeb.ChallengeView do
  use SegmentChallengeWeb, :view

  import SegmentChallengeWeb.Helpers.ChallengeHelpers

  def title("show.html", %{challenge: challenge}), do: challenge.name <> " - Segment Challenge"
  def title("index.html", _assigns), do: "Challenges - Segment Challenge"
  def title("new.html", _assigns), do: "Create a stage - Segment Challenge"

  def active_filter_class(%{params: params}, filter, value \\ nil) do
    case Map.get(params, filter) do
      ^value -> "is-active"
      _value -> ""
    end
  end

  def link_to_challenge_type(%{params: params} = conn, nil, options) do
    %{conn | params: Map.drop(params, ["type", "page"])} |> link_to(options)
  end

  def link_to_challenge_type(%{params: params} = conn, type, options) do
    params = params |> Map.delete("page") |> Map.put("type", type)

    %{conn | params: params} |> link_to(options)
  end

  def link_to_challenge_activity(%{params: params} = conn, nil, options) do
    %{conn | params: Map.drop(params, ["activity", "page"])} |> link_to(options)
  end

  def link_to_challenge_activity(%{params: params} = conn, activity, options) do
    params = params |> Map.delete("page") |> Map.put("activity", activity)

    %{conn | params: params} |> link_to(options)
  end

  def active_challenge_filter_class(%{params: %{"activity" => activity}}, :activity, activity),
    do: "is-active"

  def active_challenge_filter_class(%{params: %{"type" => type}}, :type, type), do: "is-active"

  def active_challenge_filter_class(_conn, _filter, _value), do: ""

  def challenge_pagination_links(%{params: params}, challenges) do
    opts = []

    opts =
      case Map.get(params, "activity") do
        blank when blank in [nil, ""] -> opts
        activity when is_binary(activity) -> Keyword.put(opts, :activity, activity)
      end

    opts =
      case Map.get(params, "type") do
        blank when blank in [nil, ""] -> opts
        type when is_binary(type) -> Keyword.put(opts, :type, type)
      end

    Scrivener.HTML.pagination_links(challenges, opts)
  end

  def render("scripts.edit.html", %{challenge: challenge}) do
    """
    <script type="text/javascript">
    SegmentChallenge.renderMarkdownEditor('challenge_description_markdown', {
      label: 'Describe the challenge',
      name: 'description',
      markdown: `#{String.replace(challenge.description_markdown, "`", "\\`")}`,
      rowCount: 15
    })
    </script>
    """
    |> raw
  end

  defp link_to(conn, options) do
    %{params: params, request_path: request_path} = conn

    to =
      case URI.encode_query(params) do
        "" -> request_path
        query -> "?" <> query
      end

    options
    |> Keyword.put(:to, to)
    |> Phoenix.HTML.Link.link()
  end
end
