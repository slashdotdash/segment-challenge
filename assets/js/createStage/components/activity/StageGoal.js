import React from 'react'
import PropTypes from 'prop-types'
import ValidationFailure from '../../../form/components/ValidationFailure'
import classNames from 'classnames'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const Option = ({label, value}) => (
  <option value={value}>
    {label}
  </option>
)

const GoalDistance = ({unitsOfMeasure, goal, units, singleActivityGoal, errors, onChange}) => {
  return (
    <div>
      <div className="field">
        <label className="label">Goal distance</label>
      </div>
      <div className="field has-addons">
        <div className="control">
          <input className="input" type="text" value={goal || ''} onChange={e => onChange(e.target.value, units, singleActivityGoal)} />

          <ValidationFailure error={errorFor(errors, 'goal')} />
        </div>
        <div className="control">
          <span className="select">
            <select value={units} onChange={e => onChange(goal, e.target.value, singleActivityGoal)}>
              <option value="">Please select units ...</option>
              {Object.keys(unitsOfMeasure).map(key => (<Option label={key} value={unitsOfMeasure[key]} key={key} />))}
              </select>
          </span>

          <ValidationFailure error={errorFor(errors, 'goal_units')} />
        </div>
      </div>

      <label className="checkbox">
        <input type="checkbox" value={singleActivityGoal} onChange={e => onChange(goal, units, !singleActivityGoal)} />
        In a single activity
      </label>
    </div>
  )
}

const StageGoal = ({errors, unitsOfMeasure, hasGoal, goal, units, singleActivityGoal, onChange}) => {
  if (hasGoal) {
    return (
      <GoalDistance
          unitsOfMeasure={unitsOfMeasure}
          goal={goal}
          units={units}
          singleActivityGoal={singleActivityGoal}
          errors={errors}
          onChange={onChange} />
    )
  }

  return null
}

StageGoal.propTypes = {
  errors: PropTypes.array,
  hasGoal: PropTypes.bool,
  unitsOfMeasure: PropTypes.object.isRequired,
  goal: PropTypes.string,
  units: PropTypes.string,
  singleActivityGoal: PropTypes.bool,
  onChange: PropTypes.func.isRequired
}

export default StageGoal;
