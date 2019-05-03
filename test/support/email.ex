defmodule SegmentChallenge.Test.Email do
  alias SegmentChallenge.Notifications.LostPlace
  alias SegmentChallenge.Notifications.HostChallenge

  def lost_place_email(to, %LostPlace{} = lost_place) do
    %{
      to: to,
      bcc: nil,
      subject: subject(lost_place),
      html_body: Poison.encode!(lost_place),
      text_body: ""
    }
  end

  def host_challenge_email(to, %HostChallenge{} = host_challenge) do
    %{
      to: to,
      bcc: "ben@segmentchallenge.com",
      subject: "Host your challenge",
      html_body: Poison.encode!(host_challenge),
      text_body: ""
    }
  end

  defp subject(%LostPlace{taken_by_athlete: nil, previous_rank: previous_rank, stage: stage}) do
    "You just lost #{Number.Human.number_to_ordinal(previous_rank)} place on Stage #{
      stage.stage_number
    } #{stage.name}"
  end

  defp subject(%LostPlace{taken_by_athlete: athlete, previous_rank: previous_rank, stage: stage}) do
    "#{athlete.firstname} just stole your #{Number.Human.number_to_ordinal(previous_rank)} place on Stage #{
      stage.stage_number
    }"
  end
end
