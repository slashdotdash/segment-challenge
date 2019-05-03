defmodule SegmentChallenge.Strava.Cache do
  require Logger

  alias SegmentChallenge.Strava.CachedItem

  def cached(id, struct, request_fun) when is_function(request_fun, 0) do
    case read_cache(id, struct) do
      {:ok, cached} ->
        {:ok, cached}

      {:error, :not_cached} ->
        request(id, request_fun)
    end
  end

  @doc """
  Is the given item already cached?
  """
  def cached?(id, struct) do
    case read_cache(id, struct) do
      {:ok, _cached} -> true
      {:error, :not_cached} -> false
    end
  end

  def purge(id, struct) do
    delete_cache(id, struct)

    :ok
  end

  defp request(id, request_fun) do
    case apply(request_fun, []) do
      {:ok, response} = reply ->
        write_cache(id, response)

        reply

      reply ->
        reply
    end
  end

  defp read_cache(id, struct) do
    try do
      CachedItem.get(id, struct)
    rescue
      error ->
        Logger.error(fn -> "Cache read failed: " <> inspect(error) end)
        {:error, :not_cached}
    end
  end

  defp write_cache(id, response) do
    try do
      CachedItem.insert(id, response)
    rescue
      error ->
        Logger.error(fn -> "Cache write failed: " <> inspect(error) end)
    end
  end

  defp delete_cache(id, struct) do
    try do
      CachedItem.delete(id, struct)
    rescue
      error ->
        Logger.error(fn -> "Cache delete failed: " <> inspect(error) end)
    end
  end
end
