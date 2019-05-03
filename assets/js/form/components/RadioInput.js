import React from 'react'
import PropTypes from 'prop-types'

const RadioInput = ({ name, value, selectedValue, onChange, children }) => (
  <label className="radio" key={value}>
    <input type="radio" name={name} value={value} checked={value == selectedValue} onChange={() => onChange(value)} />
    {children}
  </label>
)

RadioInput.propTypes = {
  name: PropTypes.string.isRequired,
  value: PropTypes.any,
  selectedValue: PropTypes.any,
  onChange: PropTypes.func.isRequired
}

export default RadioInput
