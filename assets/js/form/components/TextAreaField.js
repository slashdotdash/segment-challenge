import React from 'react'
import PropTypes from 'prop-types'
import ValidationFailure from './ValidationFailure'
import classNames from 'classnames';

const TextAreaField = ({ label, name, placeholder, value, rowCount, error, onChange }) => {
  const handleChange = e => onChange(e.target.value)

  const inputClass = classNames({
    'textarea': true,
    'is-danger': !!error
  })

  return (
    <div className="field">
      <label className="label">{label}</label>
      <div className="control">
        <textarea
            className={inputClass}
            type="text"
            name={name}
            value={value}
            placeholder={placeholder}
            rows={rowCount}
            onChange={handleChange} />

        <ValidationFailure error={error} />
      </div>
    </div>
  )
}

TextAreaField.propTypes = {
  label: PropTypes.string.isRequired,
  name: PropTypes.string,
  value: PropTypes.string,
  placeholder: PropTypes.string,
  error: PropTypes.string,
  rowCount: PropTypes.number.isRequired,
  onChange: PropTypes.func
}

export default TextAreaField
