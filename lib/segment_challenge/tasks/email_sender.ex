defmodule SegmentChallenge.Tasks.EmailSender do
  use Timex

  alias Ecto.Changeset
  alias SegmentChallenge.Projections.EmailProjection
  alias SegmentChallenge.Repo
  alias SegmentChallenge.Email.Mailer

  @sender_email "ben@segmentchallenge.com"

  def execute do
    now = utc_now()

    pending_emails_to_send_query()
    |> Repo.all()
    |> Enum.each(fn email ->
      case Timex.diff(now, email.send_after, :minutes) do
        send_after when send_after > 120 ->
          # Discard emails older than 2 hours
          discard_email(email)

        send_after when send_after >= 0 ->
          # Send emails that have reached their scheduled time
          claim_email(email)
          send_email(email)
          record_sent(email)

        _ ->
          # Skip emails that aren't yet scheduled
          :ok
      end
    end)
  end

  defp pending_emails_to_send_query do
    import Ecto.Query, only: [from: 2]

    from(c in EmailProjection, where: c.send_status == "pending")
  end

  # Discard emails that are too old to send
  defp discard_email(%EmailProjection{} = email) do
    email
    |> Changeset.change(send_status: "discarded")
    |> Repo.update!()
  end

  defp claim_email(%EmailProjection{} = email) do
    email
    |> Changeset.change(send_status: "sending")
    |> Repo.update!()
  end

  defp send_email(%EmailProjection{} = email) do
    import Bamboo.Email

    %EmailProjection{
      to: to,
      bcc: bcc,
      subject: subject,
      html_body: html_body,
      text_body: text_body
    } = email

    new_email()
    |> from({"Segment Challenge", @sender_email})
    |> put_header("reply-to", @sender_email)
    |> to(to)
    |> bcc(bcc)
    |> subject(subject)
    |> html_body(html_body)
    |> text_body(text_body)
    |> Mailer.deliver_now()
  end

  defp record_sent(%EmailProjection{} = email) do
    email
    |> Changeset.change(send_status: "sent", sent_at: utc_now())
    |> Repo.update!()
  end

  defp utc_now do
    SegmentChallenge.Infrastructure.DateTime.Now.to_naive() |> NaiveDateTime.truncate(:second)
  end
end
