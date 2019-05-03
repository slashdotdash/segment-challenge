import React from 'react'
import PropTypes from 'prop-types'
import RadioInput from './RadioInput'
import ValidationFailure from './ValidationFailure'
import classNames from 'classnames';

const RadioField = ({ label, name, className, values, selectedValue, error, onChange }) => {
  let controlClass = classNames({
    'control': true,
    'is-danger': !!error
  })

  let fieldClass = 'field' + (className ? ' ' + className : '')

  return (
    <div className={fieldClass}>
      <label className="label">{label}</label>
      <div className={controlClass}>
        {Object.keys(values).map(key => (
          <RadioInput key={key} name={name} value={values[key]} selectedValue={selectedValue} onChange={onChange}>
            {key}
          </RadioInput>
        ))}

        <ValidationFailure error={error} />
      </div>
    </div>
  )
}

RadioField.propTypes = {
  label: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  values: PropTypes.object,
  selectedValue: PropTypes.any,
  error: PropTypes.string,
  onChange: PropTypes.func.isRequired
}

export default RadioField
