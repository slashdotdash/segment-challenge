import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'
import ValidationFailure from '../../../form/components/ValidationFailure'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const distanceUnitsOfMeasure = {
  'Feet': 'feet',
  'Miles': 'miles',
  'Metres': 'metres',
  'Kilometres': 'kilometres'
}

const Option = ({label, value}) => (
  <option value={value}>
    {label}
  </option>
)

const RaceDistance = ({challenge, errors, updateChallenge}) => {
  const {
    challengeType,
    activityType,
    includedActivities,
    goal,
    goalUnits
  } = challenge

  return (
    <div>
      <div className="columns">
        <div className="column">
          <div className="field">
            <label className="label">Race distance</label>
          </div>
          <div className="field has-addons">
            <div className="control">
              <input className="input" type="text" value={goal || ''} onChange={e => updateChallenge({goal: e.target.value})} />

              <ValidationFailure error={errorFor(errors, 'goal')} />
            </div>
            <div className="control">
              <span className="select">
                <select value={goalUnits} onChange={e => updateChallenge({goalUnits: e.target.value})}>
                  <option value="">Please select units ...</option>
                  {Object.keys(distanceUnitsOfMeasure).map(key => (
                    <Option label={key} value={distanceUnitsOfMeasure[key]} key={key} />
                  ))}
                </select>
              </span>

              <ValidationFailure error={errorFor(errors, 'goal_units')} />
            </div>
          </div>
        </div>
        <div className="column content">
          <br />

          <p>
            Enter the virtual race distance in your desired units.
          </p>
        </div>
      </div>
    </div>
  )
}

RaceDistance.propTypes = {
  errors: PropTypes.array,
  challenge: PropTypes.shape({
    activityType: PropTypes.string,
    goal: PropTypes.string,
    goalUnits: PropTypes.string
  }),
  updateChallenge: PropTypes.func.isRequired
}

export default RaceDistance;
