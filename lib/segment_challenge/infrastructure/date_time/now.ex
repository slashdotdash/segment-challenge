defmodule SegmentChallenge.Infrastructure.DateTime.Now do
  def start_link do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  @doc """
  Get the current UTC date and time as a naive date/time
  """
  def to_naive do
    Agent.get(__MODULE__, fn now ->
      case now do
        nil -> utc_now()
        now -> now
      end
    end)
  end

  def set(%NaiveDateTime{} = now) do
    Agent.update(__MODULE__, fn _ -> now end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> nil end)
  end

  defp utc_now do
    DateTime.utc_now() |> DateTime.to_naive()
  end
end
