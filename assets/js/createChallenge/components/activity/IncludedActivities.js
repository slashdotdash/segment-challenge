import React from 'react';
import PropTypes from 'prop-types'
import ValidationFailure from '../../../form/components/ValidationFailure'
import classNames from 'classnames';

const IncludedActivities = ({ includedActivities, showAllActivities, error, onChange }) => {
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

  if (showAllActivities) {
    return (
      <div className="control is-select-list">
        {activityCheckbox('Alpine Ski', 'AlpineSki')}
        {activityCheckbox('Backcountry Ski', 'BackcountrySki')}
        {activityCheckbox('Canoeing', 'Canoeing')}
        {activityCheckbox('Crossfit', 'Crossfit')}
        {activityCheckbox('eBike Ride', 'EBikeRide')}
        {activityCheckbox('Elliptical', 'Elliptical')}
        {activityCheckbox('Golf', 'Golf')}
        {activityCheckbox('Handcycle', 'Handcycle')}
        {activityCheckbox('Hike', 'Hike')}
        {activityCheckbox('Ice Skate', 'IceSkate')}
        {activityCheckbox('Inline Skate', 'InlineSkate')}
        {activityCheckbox('Kayaking', 'Kayaking')}
        {activityCheckbox('Kitesurf', 'Kitesurf')}
        {activityCheckbox('Nordic Ski', 'NordicSki')}
        {activityCheckbox('Ride', 'Ride')}
        {activityCheckbox('Rock Climbing', 'RockClimbing')}
        {activityCheckbox('Roller Ski', 'RollerSki')}
        {activityCheckbox('Rowing', 'Rowing')}
        {activityCheckbox('Run', 'Run')}
        {activityCheckbox('Sail', 'Sail')}
        {activityCheckbox('Skateboard', 'Skateboard')}
        {activityCheckbox('Snowboard', 'Snowboard')}
        {activityCheckbox('Snowshoe', 'Snowshoe')}
        {activityCheckbox('Soccer', 'Soccer')}
        {activityCheckbox('Stair Stepper', 'StairStepper')}
        {activityCheckbox('Stand Up Paddling', 'StandUpPaddling')}
        {activityCheckbox('Surfing', 'Surfing')}
        {activityCheckbox('Swim', 'Swim')}
        {activityCheckbox('Velomobile', 'Velomobile')}
        {activityCheckbox('Virtual Ride', 'VirtualRide')}
        {activityCheckbox('Virtual Run', 'VirtualRun')}
        {activityCheckbox('Walk', 'Walk')}
        {activityCheckbox('Weight Training', 'WeightTraining')}
        {activityCheckbox('Wheelchair', 'Wheelchair')}
        {activityCheckbox('Windsurf', 'Windsurf')}
        {activityCheckbox('Workout', 'Workout')}
        {activityCheckbox('Yoga', 'Yoga')}

        <ValidationFailure error={error} />
      </div>
    )
  }

  return (
    <div className="control is-select-list">
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
