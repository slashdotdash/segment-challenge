import React, {useState} from 'react';
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { updateChallenge } from '../actions'
import CalendarField from '../../form/components/CalendarField'
import InputField from '../../form/components/InputField'
import RadioField from '../../form/components/RadioField'
import SelectField from '../../form/components/SelectField'
import IncludedActivities from '../components/activity/IncludedActivities'
import Goal from '../components/activity/Goal'
import StageList from '../components/activity/StageList'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const Stages = ({challenge, errors, updateChallenge}) => {
  const {stages} = challenge

  if (stages) {
    return (
      <StageList
          challenge={challenge}
          error={errorFor(errors, 'stages')}
          onChange={updateChallenge} />
    )
  }

  return null
}

const ActivityChallengeDetails = ({challenge, errors, updateChallenge}) => {
  const {
    challengeType,
    allowPrivateActivities,
    includedActivities,
    activityType,
    accumulateActivities,
    hasGoal
  } = challenge

  let accumulateOptions = {}

  switch (activityType) {
    case 'elevation':
      accumulateOptions['Total ' + activityType + ' gain in all activities'] = true
      accumulateOptions['Most ' + activityType + ' gain in a single activity'] = false
      break

    case undefined:
      accumulateOptions['Total activity'] = true
      accumulateOptions['Longest single activity'] = false
      break

    default:
      accumulateOptions['Total ' + activityType + ' of all activities'] = true
      accumulateOptions['Longest ' + activityType + ' of a single activity'] = false
      break
  }

  const [showAllActivities, setValue] = useState(0);

   const showAll = value => {
     setValue(value);
   }

  return (
    <div>
      <div className="columns">
        <div className="column">
          <div className="field">
            <label className="label">Which activities are included in the challenge?</label>

            <IncludedActivities
                showAllActivities={showAllActivities}
                includedActivities={includedActivities}
                error={errorFor(errors, 'included_activity_types')}
                onChange={includedActivities => updateChallenge({includedActivities})} />
          </div>

          <p>
            <a onClick={() => showAll(!showAllActivities)}>
              {showAllActivities ? 'Show less' : 'Show more'}  &hellip;
            </a>
          </p>
        </div>
        <div className="column content">
          <p>
            You can restrict the challenge to one or more activity types.
            Only selected activities will be included in the challenge.
          </p>
        </div>
      </div>

      <hr />

      <div className="columns">
        <div className="column">
          <RadioField
              label="What type of activity will be measured?"
              name="activity_type"
              values={{'Distance': 'distance', 'Duration': 'duration', 'Elevation gain': 'elevation'}}
              selectedValue={activityType}
              error={errorFor(errors, 'challenge_type')}
              onChange={activityType => updateChallenge({activityType})} />
        </div>
        <div className="column content">
          <p>
          </p>
        </div>
      </div>

      <hr />

      <div className="columns">
        <div className="column">
          <RadioField
              label="Measure total or single activity?"
              name="accumulate_activities"
              values={accumulateOptions}
              selectedValue={accumulateActivities}
              error={errorFor(errors, 'accumulate_activities')}
              onChange={accumulateActivities => updateChallenge({accumulateActivities})} />
        </div>
        <div className="column content">
          <p>
            Choose to record competitors' <strong>total</strong> activity or longest <strong>single</strong> activity.
          </p>
        </div>
      </div>

      <hr />

      <h3 className="title">Challenge goal</h3>

      <div className="columns">
        <div className="column">
          <RadioField
              label="Does the challenge have a goal?"
              name="has_goal"
              values={{'Yes': true, 'No': false}}
              selectedValue={hasGoal}
              error={errorFor(errors, 'has_goal')}
              onChange={hasGoal => updateChallenge({hasGoal})} />
        </div>
        <div className="column content">
          <p>
            A goal can be used to motivate competitors to reach a target {challengeType}.
            Competitors will be awarded a virtual badge in their trophy case when
            they achieve the challenge goal.
          </p>
        </div>
      </div>

      <Goal
          challenge={challenge}
          errors={errors}
          updateChallenge={updateChallenge} />

      <Stages
          challenge={challenge}
          errors={errors}
          updateChallenge={updateChallenge} />
    </div>
  )
}

ActivityChallengeDetails.propTypes = {
  challenge: PropTypes.shape({
    challengeType: PropTypes.string,
    includedActivities: PropTypes.array,
    activityType: PropTypes.string,
    hasGoal: PropTypes.bool,
    goal: PropTypes.string,
    goalUnits: PropTypes.string,
    singleActivityGoal: PropTypes.bool
  }).isRequired,
  errors: PropTypes.array,
  updateChallenge: PropTypes.func.isRequired
}

const mapStateToProps = state => {
  return {
    challenge: state.challenge,
    errors: state.errors
  };
}

const mapDispatchToProps = dispatch => ({
  updateChallenge: challenge => dispatch(updateChallenge(challenge))
})

export default connect(mapStateToProps, mapDispatchToProps)(ActivityChallengeDetails);
