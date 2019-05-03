import React from 'react'
import PropTypes from 'prop-types'

const FormStep = ({ step, currentStep, children }) => {
  if (step == currentStep) {
    return children
  }

  return null
}

FormStep.propTypes = {
  step: PropTypes.number.isRequired,
  currentStep: PropTypes.number.isRequired
}

export default FormStep
