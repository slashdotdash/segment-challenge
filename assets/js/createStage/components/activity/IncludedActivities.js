import React from 'react'
import PropTypes from 'prop-types'
import ValidationFailure from '../../../form/components/ValidationFailure'
import classNames from 'classnames';

const IncludedActivities = ({ includedActivities, error, onChange }) => {
  const handleChange = e => {
    let value = e.currentTarget.value
    let selected = includedActivities.slice()
    let index = selected.indexOf(value)

    if (index > -1) {
      selected.splice(index, 1)
    } else {
      selected.push(value)
    }

    onChange(selected)
  }

  let checkboxClass = classNames({
    'checkbox': true,
    'is-danger': !!error
  })

  const isChecked = value => includedActivities.includes(value)

  const activityCheckbox = (label, value) => (
    <label className={checkboxClass}>
      <input type="checkbox" name="included_activities" value={value} checked={isChecked(value)} onChange={handleChange} />
      {label}
    </label>
  )

  return (
    <div className="control">
      {activityCheckbox('Ride', 'Ride')}
      {activityCheckbox('Run', 'Run')}
      {activityCheckbox('Hike', 'Hike')}
      {activityCheckbox('Walk', 'Walk')}
      {activityCheckbox('Swim', 'Swim')}
      {activityCheckbox('Virtual Ride', 'VirtualRide')}
      {activityCheckbox('Virtual Run', 'VirtualRun')}

      <ValidationFailure error={error} />
    </div>
  )
}

IncludedActivities.propTypes = {
  includedActivities: PropTypes.array.isRequired,
  error: PropTypes.string,
  onChange: PropTypes.func.isRequired
}

export default IncludedActivities
