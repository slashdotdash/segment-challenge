import React from 'react'
import PropTypes from 'prop-types'
import SelectListOption from '../../../form/components/SelectListOption'

const ActivityType = ({ activityType, onChange }) => {
  return (
    <div>
      <SelectListOption label="Distance" value="distance" selectedValue={activityType} onSelected={onChange}>
        <p>
          Record the athlete's total distance.
        </p>
      </SelectListOption>

      <SelectListOption label="Duration" value="duration" selectedValue={activityType} onSelected={onChange}>
        <p>
          Record the total duration of the athlete's activities.
        </p>
      </SelectListOption>

      <SelectListOption label="Climbing" value="elevation" selectedValue={activityType} onSelected={onChange}>
        <p>
          For climbing enthusiasts, record the athlete's total ascent.
        </p>
      </SelectListOption>
    </div>
  )
}

ActivityType.propTypes = {
  activityType: PropTypes.string,
  onChange: PropTypes.func.isRequired
}

export default ActivityType
