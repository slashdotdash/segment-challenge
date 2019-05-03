import React from 'react'
import PropTypes from 'prop-types'
import ValidationFailure from '../../../form/components/ValidationFailure'
import classNames from 'classnames';
import moment from 'moment'

const dateFormat = 'MMMM Do, YYYY'  // e.g. March 1st, 2018
const formatDate = date => moment(date).format(dateFormat)

const StageDates = ({startDate, endDate}) => {
  const diff = endDate.getTime() - startDate.getTime()
  if (diff <= 86400000) {
    return (<span> {formatDate(startDate)}</span>)
  }

  return (<span> {formatDate(startDate)} — {formatDate(endDate)}</span>)
}

const Stage = ({stage, columnClass}) => {
  const {stageNumber, name, startDate, endDate, interval} = stage

  return (
    <div className={columnClass}>
      <p>
        <strong>{name}</strong><br />
        <i className="fa fa-calendar-o"></i>
        <small><StageDates startDate={startDate} endDate={endDate} /></small>
      </p>
    </div>
  )
}

const StageList = ({challenge, error, onChange}) => {
  const {goalRecurrence, stages} = challenge

  const columnClass = classNames({
    'column': true,
    'content': true,
    'is-3': goalRecurrence == 'day',
    'is-4': goalRecurrence != 'day',
    'is-danger': !!error
  })

  return (
    <div>
      <hr />

      <label className="label">Stages</label>

      <ValidationFailure error={error} />

      <div className="columns is-multiline">
        {stages.map(stage => (<Stage key={stage.stageNumber} stage={stage} columnClass={columnClass} />))}
      </div>
    </div>
  )
}

StageList.propTypes = {
  challenge: PropTypes.shape({
    goalRecurrence: PropTypes.string,
    stages: PropTypes.array.isRequired
  }).isRequired,
  error: PropTypes.string,
  onChange: PropTypes.func.isRequired
}

export default StageList
