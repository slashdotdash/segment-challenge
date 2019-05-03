defimpl Canada.Can, for: SegmentChallenge.Authorisation.User do
  alias SegmentChallenge.Authorisation.User

  alias SegmentChallenge.Authorisation.Policies.{
    AthleteNotificationsPolicy,
    ChallengePolicy,
    StagePolicy
  }

  alias SegmentChallenge.Stages.Stage.Commands.{
    ApproveStageLeaderboards,
    ConfigureAthleteGenderInStage,
    CreateActivityStage,
    CreateSegmentStage,
    DeleteStage,
    FlagStageEffort,
    PublishStageResults,
    RevealStage,
    SetStageDescription
  }

  alias SegmentChallenge.Commands.{
    ApproveChallengeLeaderboards,
    CancelChallenge,
    CreateChallenge,
    HostChallenge,
    JoinChallenge,
    LeaveChallenge,
    PublishChallengeResults,
    RenameChallenge,
    SetChallengeDescription,
    SubscribeAthleteToAllNotifications,
    ToggleEmailNotification
  }

  def can?(%User{} = user, :dispatch, %ApproveChallengeLeaderboards{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %ApproveStageLeaderboards{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %CancelChallenge{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %CreateChallenge{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %ConfigureAthleteGenderInStage{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %CreateActivityStage{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %CreateSegmentStage{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %DeleteStage{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %FlagStageEffort{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %HostChallenge{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %JoinChallenge{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %LeaveChallenge{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %PublishChallengeResults{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %RenameChallenge{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %RevealStage{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %PublishStageResults{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %SetChallengeDescription{} = command),
    do: ChallengePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %SetStageDescription{} = command),
    do: StagePolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %SubscribeAthleteToAllNotifications{} = command),
    do: AthleteNotificationsPolicy.can?(user, :dispatch, command)

  def can?(%User{} = user, :dispatch, %ToggleEmailNotification{} = command),
    do: AthleteNotificationsPolicy.can?(user, :dispatch, command)

  def can?(_user, _action, _command), do: false
end
