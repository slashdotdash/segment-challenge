import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import classNames from 'classnames'
import FormStep from '../../form/components/FormStep'
import ActivityStage from '../containers/ActivityStage'
import SegmentStage from '../containers/SegmentStage'
import { setFormStep } from '../actions'

const stepClass = (step, currentStep) => {
  return classNames({
    'step-item': true,
    'is-active': step == currentStep,
    'is-completed': step < currentStep,
    'is-selectable': step < currentStep
  })
}

const stepCheckmark = (step, currentStep) => {
  if (step < currentStep) {
    return (
      <span className="icon">
        <i className="fa fa-check"></i>
      </span>
    )
  }

  if (step == currentStep) {
    return (
      <span className="icon">
        <i className="fa fa-check"></i>
      </span>
    )
  }

  return null
}

const CreateStage = ({ stage, step, setFormStep }) => {
  switch (stage.stageType) {
    case 'segment':
      return (
        <div>
          <div className="steps">
            <div className={stepClass(1, step)} onClick={() => setFormStep(1)}>
              <div className="step-marker">
                {stepCheckmark(1, step)}
              </div>
              <div className="step-content">
                <p className="step-title">Step 1</p>
                <p>Strava segment</p>
              </div>
            </div>

            <div className={stepClass(2, step)}>
              <div className="step-marker">
                {stepCheckmark(2, step)}
              </div>
              <div className="step-content">
                <p className="step-title">Step 2</p>
                <p>Create stage</p>
              </div>
            </div>
          </div>

          <SegmentStage />
        </div>
      )

    case 'activity':
      return (<ActivityStage stage={stage} />)

    default:
      return null;
  }
}

CreateStage.propTypes = {
  stage: PropTypes.shape({
    stageNumber: PropTypes.number.isRequired,
    stageType: PropTypes.string
  }).isRequired,
  step: PropTypes.number.isRequired
}

const mapStateToProps = state => {
  return {
    stage: state.stage,
    step: state.formState.step
  };
}

const mapDispatchToProps = dispatch => ({
  setFormStep: step => dispatch(setFormStep(step))
})

export default connect(mapStateToProps, mapDispatchToProps)(CreateStage);
