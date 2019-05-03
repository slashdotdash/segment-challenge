import React from 'react'
import PropTypes from 'prop-types'

const ValidationFailure = ({ error }) => {
  if (error) {
    return (
      <span className="help is-danger">{error}</span>
    )
  }

  return null;
}

ValidationFailure.propTypes = {
  error: PropTypes.string
}

export default ValidationFailure
