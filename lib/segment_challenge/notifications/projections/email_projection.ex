defmodule SegmentChallenge.Projections.EmailProjection do
  use Ecto.Schema

  schema "emails" do
    field(:athlete_uuid, :string)
    field(:type, :string)
    field(:to, :string)
    field(:bcc, :string)
    field(:subject, :string)
    field(:html_body, :string)
    field(:text_body, :string)
    field(:send_status, :string, default: "pending")
    field(:send_after, :naive_datetime)
    field(:sent_at, :naive_datetime)

    timestamps()
  end
end
