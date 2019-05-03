import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames';

const SubmitButton = ({ label, disabled, loading, onSubmit, onCancel }) => {
  const buttonClass = classNames({
    'button': true,
    'is-primary': true,
    'is-loading': loading
  })

  return (
    <div className="control">
      <button className={buttonClass} disabled={disabled} onClick={e => onSubmit()}>
        {label}
      </button>
      <a className="button is-link" onClick={onCancel}>Cancel</a>
    </div>
  )
}

SubmitButton.propTypes = {
  label: PropTypes.string.isRequired,
  disabled: PropTypes.bool.isRequired,
  loading: PropTypes.bool.isRequired,
  onSubmit: PropTypes.func.isRequired,
  onCancel: PropTypes.func
}

export default SubmitButton
