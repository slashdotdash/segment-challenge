import React from 'react'
import { render } from 'react-dom'
import MarkdownField from '../form/components/MarkdownField'

class MarkdownEditor extends React.Component {
  constructor(props) {
    super(props)
    this.state = {markdown: props.markdown}
  }

  setMarkdown(markdown) {
    this.setState({markdown: markdown})
  }

  render() {
    const {label, name, rowCount} = this.props
    const {markdown} = this.state
    const onChange = this.setMarkdown.bind(this)

    return (
      <MarkdownField label={label} name={name} value={markdown} rowCount={rowCount} onChange={onChange} />
    )
  }
}

const renderMarkdownEditor = (element, config) => {
  const {label, name, markdown, rowCount} = config

  render(
    <MarkdownEditor label={label} name={name} markdown={markdown} rowCount={rowCount} onChange={markdown => console.log('changed')} />,
    document.getElementById(element)
  )
}

window.SegmentChallenge = window.SegmentChallenge || {};
window.SegmentChallenge.renderMarkdownEditor = renderMarkdownEditor;

export default renderMarkdownEditor
