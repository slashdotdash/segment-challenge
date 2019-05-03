import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import FormStep from '../../form/components/FormStep'
import Step from '../../form/components/Step'
import StravaClubProvider from './StravaClubProvider'
import ChallengeDetails from './ChallengeDetails'
import ActivityChallengeDetails from './ActivityChallengeDetails'
import VirtualRaceDetails from './VirtualRaceDetails'
import SubmitButton from '../../form/components/SubmitButton'
import { cancelChallenge, createChallenge, setFormStep } from '../actions'

const ActivityChallenge = ({challengeType}) => {
  switch (challengeType) {
    case 'activity':
      return (
        <div>
          <ActivityChallengeDetails />

          <hr />
        </div>
      )

    case 'race':
      return (
        <div>
          <VirtualRaceDetails />

          <hr />
        </div>
      )

    default:
      return null;
  }

}

const describeChallengeType = challengeType => {
  switch (challengeType) {
    case 'segment':
      return 'Segment Challenge'

    case 'activity':
      return 'Activity Challenge'

    case 'race':
      return 'Virtual Race'
  }
}

const CreateChallenge = ({challenge, formState, redirectTo, cancelChallenge, createChallenge, setFormStep}) => {
  const {challengeType, club} = challenge
  const {step} = formState

  return (
    <div>
      <div className="steps">
        <Step step={1} currentStep={step} onSelect={setFormStep} label="Hosting club" />
        <Step step={2} currentStep={step} onSelect={setFormStep} label="Create challenge" />
      </div>

      <FormStep step={1} currentStep={step}>
        <h1 className="title">Club hosting the {describeChallengeType(challengeType)}</h1>
        <h2 className="subtitle">Select one of your Strava clubs to host the challenge</h2>

        <StravaClubProvider />
      </FormStep>

      <FormStep step={2} currentStep={step}>
        <h1 className="title">About the  {describeChallengeType(challengeType)}</h1>
        <h2 className="subtitle">Hosted by <strong>{club && club.name}</strong></h2>

        <hr />

        <ChallengeDetails />

        <hr />

        <ActivityChallenge challengeType={challengeType} />

        <SubmitButton
            label="Create challenge"
            disabled={formState.submitting}
            loading={formState.loading}
            onSubmit={() => createChallenge(challenge)}
            onCancel={() => cancelChallenge(redirectTo)} />
      </FormStep>
    </div>
  )
}

CreateChallenge.propTypes = {
  challenge: PropTypes.shape({
    challengeType: PropTypes.string.isRequired,
    club: PropTypes.object
  }),
  formState: PropTypes.shape({
    step: PropTypes.number.isRequired
  }),
  redirectTo: PropTypes.string.isRequired
}

const mapStateToProps = state => {
  return {
    challenge: state.challenge,
    formState: state.formState,
    redirectTo: state.redirectTo
  };
}

const mapDispatchToProps = dispatch => ({
  cancelChallenge: url => dispatch(cancelChallenge(url)),
  createChallenge: challenge => dispatch(createChallenge(challenge)),
  setFormStep: step => dispatch(setFormStep(step))
})

export default connect(mapStateToProps, mapDispatchToProps)(CreateChallenge);
