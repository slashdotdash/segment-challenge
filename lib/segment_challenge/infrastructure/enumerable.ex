defmodule SegmentChallenge.Enumerable do
  def pluck(enumerable, field) do
    Enum.map(enumerable, &Map.get(&1, field))
  end

  @doc """
  Remove `nil` from the given enumerable

  iex> SegmentChallenge.Enumerable.compact([1, nil, 3, nil, 5])
  [1, 3, 5]

  """
  def compact(enumerable) do
    Enum.reject(enumerable, &is_nil/1)
  end

  def map_to_struct(enumerable, struct) do
    Enum.map(enumerable, &to_struct(struct, &1))
  end

  def map_to_struct(enumerable, struct, mapper) when is_function(mapper, 1) do
    enumerable
    |> Enum.map(&to_struct(struct, &1))
    |> Enum.map(&mapper.(&1))
  end

  defp to_struct(struct, %_{} = item), do: struct(struct, Map.from_struct(item))
  defp to_struct(struct, fields), do: struct(struct, fields)
end
