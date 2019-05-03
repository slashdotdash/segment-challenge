import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { updateChallenge } from '../actions'
import CalendarField from '../../form/components/CalendarField'
import InputField from '../../form/components/InputField'
import RadioField from '../../form/components/RadioField'
import SelectField from '../../form/components/SelectField'
import IncludedActivities from '../components/activity/IncludedActivities'
import RaceDistance from '../components/race/RaceDistance'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

// const activityTypes = {
//   'Ride': 'Ride',
//   'Run': 'Run',
//   'Hike': 'Hike',
//   'Walk': 'Walk',
//   'Swim': 'Swim',
//   'Virtual Ride': 'VirtualRide',
//   'Virtual Run': 'VirtualRun'
// }

const activityTypes = {
  'Alpine Ski': 'AlpineSki',
  'Backcountry Ski': 'BackcountrySki',
  'Canoeing': 'Canoeing',
  'Hike': 'Hike',
  'Kayaking': 'Kayaking',
  'Kitesurf': 'Kitesurf',
  'Nordic Ski': 'NordicSki',
  'Ride': 'Ride',
  'Rowing': 'Rowing',
  'Run': 'Run',
  'Snowboard': 'Snowboard',
  'Snowshoe': 'Snowshoe',
  'Stand Up Paddling': 'StandUpPaddling',
  'Swim': 'Swim',
  'Virtual Ride': 'VirtualRide',
  'Virtual Run': 'VirtualRun',
  'Walk': 'Walk',
  'Wheelchair': 'Wheelchair'
}
const VirtualRaceDetails = ({challenge, errors, updateChallenge}) => {
  const {
    challengeType,
    allowPrivateActivities,
    includedActivity,
    activityType
  } = challenge

  return (
    <div>
      <div className="columns">
        <div className="column">
          <RadioField
              label="Which type of activity is allowed?"
              name="includedActivity"
              values={activityTypes}
              selectedValue={includedActivity}
              error={errorFor(errors, 'included_activity_types')}
              className="is-radio-list"
              onChange={includedActivity => updateChallenge({includedActivity})} />
        </div>
        <div className="column content">
          <br />
          <p>
            Only activities of the allowed type will be included in the challenge.
          </p>
        </div>
      </div>

      <hr />

      <RaceDistance
        challenge={challenge}
        errors={errors}
        updateChallenge={updateChallenge} />
    </div>
  )
}

VirtualRaceDetails.propTypes = {
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

export default connect(mapStateToProps, mapDispatchToProps)(VirtualRaceDetails);
