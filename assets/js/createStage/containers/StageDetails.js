import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { updateStage } from '../actions'
import CalendarField from '../../form/components/CalendarField'
import InputField from '../../form/components/InputField'
import TextAreaField from '../../form/components/TextAreaField'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const StageDetails = ({ stage, errors, updateStage }) => {
  return (
    <div>
      <InputField
          label="Name of the stage"
          value={stage.name}
          error={errorFor(errors, 'name')}
          onChange={name => updateStage({name})} />

      <TextAreaField
          label="Describe the stage"
          value={stage.description}
          rowCount={3}
          error={errorFor(errors, 'description')}
          onChange={description => updateStage({description})} />

      <hr />

      <div className="columns">
        <div className="column">
          <CalendarField
              label="Start and end dates"
              placeholder="Click to select the dates"
              minDate={stage.minStartDate}
              maxDate={stage.maxEndDate}
              startDate={stage.startDate}
              endDate={stage.endDate}
              error={errorFor(errors, 'start_date') || errorFor(errors, 'start_date_local') || errorFor(errors, 'end_date') || errorFor(errors, 'end_date_local')}
              onSelected={dates => updateStage(dates)} />
        </div>
        <div className="column content">
          <br />
          <p>
            You can only select dates within the challenge period.
            Stages must be contiguous and cannot overlap.
          </p>
        </div>
      </div>
    </div>
  )
}

StageDetails.propTypes = {
  stage: PropTypes.shape({
    name: PropTypes.string
  }).isRequired
}

const mapStateToProps = state => {
  return {
    errors: state.errors,
    stage: state.stage
  };
}

const mapDispatchToProps = dispatch => ({
  updateStage: stage => dispatch(updateStage(stage))
})

export default connect(mapStateToProps, mapDispatchToProps)(StageDetails);
