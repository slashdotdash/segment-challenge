import React from 'react'
import PropTypes from 'prop-types'
import ReactMarkdown from 'react-markdown'
import classNames from 'classnames';
import TextAreaField from './TextAreaField'
import ValidationFailure from './ValidationFailure'

const MarkdownPreview = ({value, placeholder}) => {
  if (!value) {
    return (
      <p><br />{placeholder}</p>
    )
  }

  return (
    <div>
      <label className="label">Preview</label>

      <div className="content is-medium">
        <ReactMarkdown source={value} />
      </div>
    </div>
  )
}

const MarkdownField = ({label, name, placeholder, value, rowCount, error, onChange}) => {
  const handleChange = e => onChange(e.target.value)

  const inputClass = classNames({
    'textarea': true,
    'is-danger': !!error
  })

  return (
    <div className="columns">
      <div className="column">
        <TextAreaField
            label={label}
            name={name}
            value={value}
            rowCount={rowCount}
            error={error}
            onChange={onChange} />

        <p className="help">
          <a href="https://www.markdownguide.org/basic-syntax" target="_blank">Markdown formatting</a> is supported
        </p>
      </div>
      <div className="column">
        <MarkdownPreview value={value} placeholder={placeholder} />
      </div>
    </div>
  )
}

MarkdownField.propTypes = {
  label: PropTypes.string.isRequired,
  name: PropTypes.string,
  value: PropTypes.string,
  placeholder: PropTypes.string,
  error: PropTypes.string,
  rowCount: PropTypes.number.isRequired,
  onChange: PropTypes.func
}

export default MarkdownField
