import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames';
import ValidationFailure from './ValidationFailure'

const InputField = ({ label, placeholder, value, error, onChange }) => {
  const handleChange = e => onChange(e.target.value)

  let inputClass = classNames({
    'input': true,
    'is-danger': !!error
  })

  return (
    <div className="field">
      <label className="label">{label}</label>
      <div className="control">
        <input
            className={inputClass}
            type="text"
            placeholder={placeholder}
            value={value}
            onChange={handleChange}
            />

        <ValidationFailure error={error} />
      </div>
    </div>
  )
}

InputField.propTypes = {
  label: PropTypes.string.isRequired,
  value: PropTypes.string,
  placeholder: PropTypes.string,
  error: PropTypes.string,
  onChange: PropTypes.func.isRequired
}

export default InputField
