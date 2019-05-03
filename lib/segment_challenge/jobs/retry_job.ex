defmodule SegmentChallenge.Jobs.RetryJob do
  def retry(module, args) do
    case Keyword.get(args, :failures, 0) do
      failures when failures <= 3 ->
        failure_count = failures + 1
        args = Keyword.put(args, :failures, failure_count)
        delay = :timer.minutes(15 * failure_count * failure_count)

        {:ok, _job} = Rihanna.schedule(module, args, in: delay)

        :ok

      _failures ->
        :ok
    end
  end
end
