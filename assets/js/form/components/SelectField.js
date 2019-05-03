import React from 'react'
import PropTypes from 'prop-types'
import ValidationFailure from './ValidationFailure'
import classNames from 'classnames';

const Option = ({label, value}) => (
  <option value={value}>
    {label}
  </option>
)

const SelectField = ({ label, values, value, placeholder, error, onChange }) => {
  const selectClass = classNames({
    'select': true,
    'is-danger': !!error
  })

  return (
    <div className="field">
      <label className="label">{label}</label>
      <div className="control">
        <span className={selectClass}>
          <select value={value} onChange={e => onChange(e.target.value)}>
            <Option label={placeholder} value="" />
            {Object.keys(values).map(key => (<Option label={key} value={values[key]} key={key} />))}
          </select>
        </span>

        <ValidationFailure error={error} />
      </div>
    </div>
  )
}

SelectField.propTypes = {
  label: PropTypes.string.isRequired,
  values: PropTypes.object,
  value: PropTypes.string,
  placeholder: PropTypes.string,
  error: PropTypes.string,
  onChange: PropTypes.func.isRequired
}

export default SelectField
