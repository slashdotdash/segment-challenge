defmodule SegmentChallenge.Repo do
  use Ecto.Repo, otp_app: :segment_challenge, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 12

  import Ecto.Query

  alias SegmentChallenge.Repo

  defmodule Page do
    defstruct entries: [], page_number: 1

    defimpl Enumerable do
      def count(_page), do: {:error, __MODULE__}

      def member?(_page, _value), do: {:error, __MODULE__}

      def reduce(%Page{entries: entries}, acc, fun) do
        Enumerable.reduce(entries, acc, fun)
      end

      def slice(_page), do: {:error, __MODULE__}
    end
  end

  def next_page(query, params) do
    page_number = params |> Map.get("page", "1") |> String.to_integer()
    page_size = params |> Map.get("page_size", "20") |> String.to_integer()
    offset = page_size * (page_number - 1)
    entries = Repo.all(from(p in query, limit: ^page_size, offset: ^offset))

    %Page{entries: entries, page_number: page_number}
  end
end
