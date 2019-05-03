defmodule SegmentChallenge.Challenges.Services.UrlSlugs.UniqueSlugger do
  use GenServer

  alias SegmentChallenge.Projections.Slugs.AllUrlSlugsQuery
  alias SegmentChallenge.Repo

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_args) do
    GenServer.cast(self(), :fetch_slugs)

    {:ok, %{}}
  end

  @doc """
  Slugify the given text and ensure that it is unique within the given context.

  A slug will contain only characters A-Za-z0-9 and the default seperator -.

  If the generated slug is already taken, append a numeric suffix and keep incrementing until a unique slug is found.

  ## Examples

  - "title", "title-2", "title-3", "title-4", etc.
  """
  @spec slugify(String.t(), String.t(), String.t()) ::
          {:ok, slug :: String.t()} | {:error, reason :: term}
  def slugify(context, source_uuid, text) do
    slug = Slugger.slugify_downcase(text)

    GenServer.call(__MODULE__, {:claim_slug, slug, context, source_uuid})
  end

  @doc """
  Fetch all URL slugs from the database to prepopulate the reserved slugs
  """
  def handle_cast(:fetch_slugs, _state) do
    state =
      AllUrlSlugsQuery.new()
      |> Repo.all()
      |> Enum.group_by(
        fn {source, _source_uuid, _slug} -> source end,
        fn {_source, source_uuid, slug} -> {source_uuid, slug} end
      )
      |> Enum.reduce(%{}, fn {source, values}, slugs ->
        values =
          Enum.reduce(values, %{}, fn {source_uuid, slug}, values ->
            Map.put(values, slug, source_uuid)
          end)

        Map.put(slugs, source, values)
      end)

    {:noreply, state}
  end

  def handle_call({:claim_slug, slug, context, source_uuid}, _from, slugs) do
    {state, slug} = ensure_unique_slug(slugs, slug, context, source_uuid)

    {:reply, {:ok, slug}, state}
  end

  # Ensure the given slug is unique, if not increment the suffix and try again.
  defp ensure_unique_slug(slugs, slug, context, source_uuid, suffix \\ 1)

  defp ensure_unique_slug(slugs, "", context, source_uuid, suffix),
    do: ensure_unique_slug(slugs, source_uuid, context, source_uuid, suffix)

  defp ensure_unique_slug(slugs, slug, context, source_uuid, suffix) do
    unique_slug = slug_with_suffix(slug, suffix)

    case exists?(slugs, context, source_uuid, unique_slug) do
      true ->
        ensure_unique_slug(slugs, slug, context, source_uuid, suffix + 1)

      false ->
        {_, slugs} =
          Map.get_and_update(slugs, context, fn assigned ->
            updated =
              case assigned do
                nil -> %{unique_slug => source_uuid}
                assigned -> Map.put(assigned, unique_slug, source_uuid)
              end

            {assigned, updated}
          end)

        {slugs, unique_slug}
    end
  end

  @reserved_slugs [
    "activity",
    "approve",
    "edit",
    "host",
    "join",
    "leaderboards",
    "results",
    "stage",
    "stages"
  ]

  # Does the slug exist for the given context?
  defp exists?(_slugs, _context, _source_uuid, slug) when slug in @reserved_slugs, do: true

  defp exists?(slugs, context, source_uuid, slug) do
    slugs
    |> Map.get(context, %{})
    |> Map.get(slug)
    |> case do
      nil -> false
      ^source_uuid -> false
      _ -> true
    end
  end

  defp slug_with_suffix(slug, 1), do: slug
  defp slug_with_suffix(slug, suffix), do: "#{slug}-#{suffix}"
end
