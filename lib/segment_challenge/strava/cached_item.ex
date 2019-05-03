defmodule SegmentChallenge.Strava.CachedItem do
  use Ecto.Schema
  import Ecto.Query

  alias SegmentChallenge.Repo
  alias SegmentChallenge.Strava.CachedItem

  @primary_key false
  schema "strava_cache" do
    field(:strava_id, :integer, primary_key: true)
    field(:strava_type, :string, primary_key: true)
    field(:payload, :string, null: false)

    timestamps()
  end

  def get(id, struct) do
    case Repo.get_by(CachedItem, strava_id: id, strava_type: type(struct)) do
      %CachedItem{} = item ->
        %CachedItem{payload: payload} = item

        {:ok, decode(struct, payload)}

      nil ->
        {:error, :not_cached}
    end
  end

  def insert(id, payload) do
    strava_type = type(payload)
    payload = Poison.encode!(payload)

    item = %CachedItem{
      strava_id: id,
      strava_type: strava_type,
      payload: payload
    }

    Repo.insert(item,
      on_conflict: [set: [payload: payload]],
      conflict_target: [:strava_id, :strava_type]
    )
  end

  def delete(id, struct) do
    strava_type = type(struct)
    query = from(c in CachedItem, where: c.strava_id == ^id and c.strava_type == ^strava_type)

    Repo.delete_all(query)
  end

  defp decode(struct, cached) do
    options = %{:as => struct(struct)}

    cached
    |> Poison.Parser.parse!(options)
    |> Strava.Deserializer.transform(options)
  end

  defp type(struct) when is_atom(struct), do: Atom.to_string(struct)
  defp type(struct) when is_map(struct), do: Atom.to_string(struct.__struct__)
end
