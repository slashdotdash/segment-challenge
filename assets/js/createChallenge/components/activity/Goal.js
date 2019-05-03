import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'
import ValidationFailure from '../../../form/components/ValidationFailure'
import RadioField from '../../../form/components/RadioField'
import RadioInput from '../../../form/components/RadioInput'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const unitsOfMeasure = activityType => {
  switch (activityType) {
    case 'distance':
    case 'elevation':
      return {
        'Feet': 'feet',
        'Miles': 'miles',
        'Metres': 'metres',
        'Kilometres': 'kilometres'
      }

    case 'duration':
      return {
        'Seconds': 'seconds',
        'Minutes': 'minutes',
        'Hours': 'hours',
        'Days': 'days'
      }

    default:
     return {}
  }
}

const Option = ({label, value}) => (
  <option value={value}>
    {label}
  </option>
)

const GoalRecurrence = ({goalRecurrence, error, onChange}) => {
  let controlClass = classNames({
    'control': true,
    'is-danger': !!error
  })

  return (
    <div className="field">
      <label className="label">Goal recurrence</label>
      <div className={controlClass}>
        <ul>
          <li>
            <RadioInput name="goal_recurrence" value="none" selectedValue={goalRecurrence} onChange={onChange}>
              <strong>None</strong> &mdash; goal applies to entire challenge duration
            </RadioInput>
          </li>

          <li>
            <RadioInput name="goal_recurrence" value="day" selectedValue={goalRecurrence} onChange={onChange}>
              <strong>Daily</strong> &mdash; competitors must achieve the goal every day during the challenge
            </RadioInput>
          </li>

          <li>
            <RadioInput name="goal_recurrence" value="week" selectedValue={goalRecurrence} onChange={onChange}>
              <strong>Weekly</strong> &mdash; competitors must achieve the goal each week during the challenge
            </RadioInput>
          </li>

          <li>
            <RadioInput name="goal_recurrence" value="month" selectedValue={goalRecurrence} onChange={onChange}>
              <strong>Monthly</strong> &mdash; competitors must achieve the goal each calendar month
            </RadioInput>
          </li>
        </ul>

        <ValidationFailure error={error} />
      </div>
    </div>
  )
}

const GoalDistance = ({challenge, errors, updateChallenge}) => {
  const {
    challengeType,
    allowPrivateActivities,
    accumulateActivities,
    activityType,
    includedActivities,
    hasGoal,
    goal,
    goalUnits,
    goalRecurrence,
  } = challenge

  let activityGoal;
  if (accumulateActivities === true) {
    activityGoal = (
      <p>
        A total activity goal allows competitors to achieve the target over multiple activities,
        such as run a marathon over many activities.
      </p>
    )
  } else if (accumulateActivities == false) {
    activityGoal = (
      <p>
      A single activity goal will require competitors to achieve the target in one activity,
      such as 100 miles in a single ride or 10km in one run.
      </p>
    )
  }

  const goalUnitsOfMeasure = unitsOfMeasure(activityType)

  return (
    <div>
      <div className="columns">
        <div className="column">
          <div className="field">
            <label className="label">Goal {challengeType}</label>
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
                  {Object.keys(goalUnitsOfMeasure).map(key => (
                    <Option label={key} value={goalUnitsOfMeasure[key]} key={key} />
                  ))}
                  </select>
              </span>

              <ValidationFailure error={errorFor(errors, 'goal_units')} />
            </div>
          </div>
        </div>
        <div className="column content">
          <p>
            Enter the {challengeType} goal in your desired units.
          </p>
          {activityGoal}
        </div>
      </div>

      <div className="columns">
        <div className="column">
          <GoalRecurrence
              goalRecurrence={goalRecurrence}
              error={errorFor(errors, 'goal_recurrence')}
              onChange={goalRecurrence => updateChallenge({goalRecurrence})} />
        </div>
        <div className="column content">
          <p>
            You can require competitors to achieve the goal on a regular basis by specifying the recurrence.
          </p>

          <p>
            Select <strong>None</strong> to have the goal apply to the challenge start and end dates.
          </p>

          <p>
            Selecting <strong>Daily</strong>, <strong>Weekly</strong>, or <strong>Monthly</strong> will
            automatically create one or more stages covering the entire challenge duration.
          </p>
        </div>
      </div>
    </div>
  )
}

const Goal = ({challenge, errors, updateChallenge}) => {
  const {hasGoal} = challenge

  if (hasGoal) {
    return (
      <GoalDistance
          challenge={challenge}
          errors={errors}
          updateChallenge={updateChallenge} />
    )
  }

  return null
}

Goal.propTypes = {
  errors: PropTypes.array,
  challenge: PropTypes.shape({
    hasGoal: PropTypes.bool,
    activityType: PropTypes.string,
    goalType: PropTypes.string,
    goal: PropTypes.string,
    goalUnits: PropTypes.string,
    goalRecurrence: PropTypes.string
  }),
  updateChallenge: PropTypes.func.isRequired
}

export default Goal;
