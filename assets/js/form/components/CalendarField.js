import React from 'react'
import PropTypes from 'prop-types'
import Flatpickr from 'react-flatpickr'
import classNames from 'classnames'
import ValidationFailure from './ValidationFailure'

const dateOnly = d => {
  if (d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate())
  }
}

const defaultValue = ({startDate, endDate, minDate, maxDate}) => {
  if ((minDate || startDate) && endDate) {
    let startDate = minDate || startDate
    let endDate = endDate

    return [dateOnly(startDate), dateOnly(endDate)]
  } else if (minDate) {
    return [dateOnly(minDate)]
  }
}

const onChange = minDate => {
  return (selectedDates, displayDate, calendar) => {
    if (selectedDates && selectedDates.length === 1) {
      let selectedDate = selectedDates[0]

      // Force start date to be the minimum
      if (selectedDate !== minDate) {
        calendar.setDate([minDate, dateOnly(selectedDate)])
      }
    }
  }
}

const onClose = onSelected => {
  return (selectedDates, displayDate, calendar) => {
    if (selectedDates.length !== 2) {
      onSelected({startDate: null, endDate: null})
      return
    }

    let startDate = selectedDates[0]
    let endDate = selectedDates[1]

    onSelected({startDate: dateOnly(startDate), endDate: dateOnly(endDate)})
  }
}

const CalendarField = ({label, placeholder, startDate, endDate, minDate, maxDate, error, onSelected}) => {
  let options = {
    defaultValue: defaultValue({startDate, endDate, minDate, maxDate}),
    mode: 'range',
    enableTime: false,
    dateFormat: 'l J F Y',
    minDate: minDate,
    maxDate: maxDate,
    locale: {
      firstDayOfWeek: 1
    }
  }

  let calendarClass = classNames({
    'input': true,
    'is-danger': !!error
  })

  return (
    <div className="field">
      <label className="label">{label}</label>
      <div className="control">
        <Flatpickr
            className={calendarClass}
            value={[startDate, endDate]}
            onChange={onChange(minDate)}
            onClose={onClose(onSelected)}
            options={options} />

        <ValidationFailure error={error} />
      </div>
    </div>
  )
}

CalendarField.propTypes = {
  label: PropTypes.string.isRequired,
  startDate: PropTypes.instanceOf(Date),
  endDate: PropTypes.instanceOf(Date),
  minDate: PropTypes.instanceOf(Date),
  maxDate: PropTypes.instanceOf(Date),
  placeholder: PropTypes.string,
  error: PropTypes.string,
  onSelected: PropTypes.func
}

export default CalendarField
