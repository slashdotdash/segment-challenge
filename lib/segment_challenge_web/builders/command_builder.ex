defmodule SegmentChallengeWeb.CommandBuilder do
  alias SegmentChallengeWeb.{
    ApproveChallengeLeaderboardsBuilder,
    ApproveStageLeaderboardsBuilder,
    CancelChallengeBuilder,
    CreateChallengeBuilder,
    CreateStageBuilder,
    ConfigureAthleteGenderInStageBuilder,
    DeleteStageBuilder,
    FlagStageEffortBuilder,
    HostChallengeBuilder,
    JoinChallengeBuilder,
    LeaveChallengeBuilder,
    PublishChallengeResultsBuilder,
    PublishStageResultsBuilder,
    RenameChallengeBuilder,
    RevealStageBuilder,
    SetChallengeDescriptionBuilder,
    SetStageDescriptionBuilder,
    SubscribeAthleteToAllNotificationsBuilder,
    ToggleEmailNotificationBuilder
  }

  def build("ApproveChallengeLeaderboards", conn, params),
    do: ApproveChallengeLeaderboardsBuilder.build(conn, params)

  def build("ApproveStageLeaderboards", conn, params),
    do: ApproveStageLeaderboardsBuilder.build(conn, params)

  def build("CancelChallenge", conn, params),
    do: CancelChallengeBuilder.build(conn, params)

  def build("ConfigureAthleteGenderInStage", conn, params),
    do: ConfigureAthleteGenderInStageBuilder.build(conn, params)

  def build("CreateChallenge", conn, params),
    do: CreateChallengeBuilder.build(conn, params)

  def build("CreateStage", conn, params),
    do: CreateStageBuilder.build(conn, params)

  def build("DeleteStage", conn, params),
    do: DeleteStageBuilder.build(conn, params)

  def build("FlagStageEffort", conn, params),
    do: FlagStageEffortBuilder.build(conn, params)

  def build("HostChallenge", conn, params),
    do: HostChallengeBuilder.build(conn, params)

  def build("JoinChallenge", conn, params),
    do: JoinChallengeBuilder.build(conn, params)

  def build("LeaveChallenge", conn, params),
    do: LeaveChallengeBuilder.build(conn, params)

  def build("PublishChallengeResults", conn, params),
    do: PublishChallengeResultsBuilder.build(conn, params)

  def build("PublishStageResults", conn, params),
    do: PublishStageResultsBuilder.build(conn, params)

  def build("RenameChallenge", conn, params),
    do: RenameChallengeBuilder.build(conn, params)

  def build("RevealStage", conn, params),
    do: RevealStageBuilder.build(conn, params)

  def build("SetChallengeDescription", conn, params),
    do: SetChallengeDescriptionBuilder.build(conn, params)

  def build("SetStageDescription", conn, params),
    do: SetStageDescriptionBuilder.build(conn, params)

  def build("SubscribeAthleteToAllNotifications", conn, params),
    do: SubscribeAthleteToAllNotificationsBuilder.build(conn, params)

  def build("ToggleEmailNotification", conn, params),
    do: ToggleEmailNotificationBuilder.build(conn, params)
end
