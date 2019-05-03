import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'

const SelectListOption = ({label, value, selectedValue, disabled, children, onSelected}) => {
  const segmentClass = classNames({
    box: true,
    'is-active': value == selectedValue
  })

  return (
    <div className={segmentClass}>
      <div className="columns">
        <div className="column has-vertically-aligned-content is-2">
          <h3 className="title is-5">{label}</h3>
        </div>
        <div className="column">
          <div className="content">
            {children}
          </div>
        </div>
        <div className="column has-vertically-aligned-content is-2">
          <button className="button is-primary is-outlined is-fullwidth" onClick={() => onSelected(value)} disabled={disabled}>
            Select
          </button>
        </div>
      </div>
    </div>
  )
}

export default SelectListOption
