import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'

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

const handleClick = (step, currentStep, onSelect) => {
  if (step < currentStep) {
    onSelect(step)
  }
}

const Step = ({ label, step, currentStep, children, onSelect }) => (
  <div className={stepClass(step, currentStep)} onClick={() => handleClick(step, currentStep, onSelect)}>
    <div className="step-marker">
      {stepCheckmark(step, currentStep)}
    </div>
    <div className="step-content">
      <p className="step-title">Step {step}</p>
      <p>{label}</p>
    </div>
  </div>
)

Step.propTypes = {
  label: PropTypes.string.isRequired,
  step: PropTypes.number.isRequired,
  currentStep: PropTypes.number.isRequired,
  onSelect: PropTypes.func.isRequired
}

export default Step
