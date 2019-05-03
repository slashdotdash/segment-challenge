import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { cancelStage, createStage, setStravaSegment, fetchStravaSegments, updateStage } from '../actions'
import classNames from 'classnames'
import CalendarField from '../../form/components/CalendarField'
import FormStep from '../../form/components/FormStep'
import SelectField from '../../form/components/SelectField'
import SegmentList from '../components/segment/SegmentList'
import StageDetails from './StageDetails'
import SubmitButton from '../../form/components/SubmitButton'
import TextAreaField from '../../form/components/TextAreaField'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const segmentTypes = {
  'Mountain': 'mountain',
  'Rolling': 'rolling',
  'Flat': 'flat'
}

class SegmentStage extends React.Component {
  componentDidMount() {
    if (!this.props.stravaSegments.loaded) {
      this.props.fetchStravaSegments()
    }
  }

  render() {
    const {loading, segments} = this.props.stravaSegments
    const {errors, formState, redirectTo, stage, createStage, fetchStravaSegments, setStravaSegment, updateStage} = this.props
    const {segmentType, stravaSegment, startDescription, endDescription} = this.props.stage

    return (
      <div>
        <FormStep step={1} currentStep={formState.step}>
          <h3 className="title">Strava segment</h3>
          <h4 className="subtitle">Select one of your starred Strava segments</h4>

          <SegmentList
              loading={loading}
              segments={segments}
              selectedSegment={stravaSegment}
              error={errorFor(errors, 'strava_segment_id')}
              onRefresh={fetchStravaSegments}
              onSelected={setStravaSegment} />
        </FormStep>

        <FormStep step={2} currentStep={formState.step}>
          <h1 className="title">Create stage</h1>
          <h2 className="subtitle">{stravaSegment && stravaSegment.name}</h2>

          <StageDetails />

          <hr />

          <div className="columns">
            <div className="column">
              <SelectField
                  label="Segment type"
                  values={segmentTypes}
                  value={segmentType}
                  placeholder="Please select a segment type ..."
                  error={errorFor(errors, 'stage_type')}
                  onChange={segmentType => updateStage({segmentType})} />
            </div>
            <div className="column content">
              <p>
                Segment type affects the point scoring for the stage.
              </p>
              <ul>
                <li>Mountain stages &mdash; double KOM/QOM points.</li>
                <li>Flat stages &mdash; double sprint points.</li>
              </ul>
            </div>
          </div>

          <hr />

          <TextAreaField
              label="Describe where the segment starts"
              value={startDescription}
              rowCount={2}
              error={errorFor(errors, 'start_description')}
              onChange={startDescription => updateStage({startDescription})} />

          <TextAreaField
              label="Describe where the segment finishes"
              value={endDescription}
              rowCount={2}
              error={errorFor(errors, 'end_description')}
              onChange={endDescription => updateStage({endDescription})} />

          <hr />

          <SubmitButton
              label="Create stage"
              disabled={formState.submitting}
              loading={formState.loading}
              onSubmit={() => createStage(stage)}
              onCancel={() => cancelStage(redirectTo)} />
        </FormStep>
      </div>
    )
  }
}

SegmentStage.propTypes = {
  errors: PropTypes.array,
  formState: PropTypes.shape({
    loading: PropTypes.bool.isRequired,
    submitting: PropTypes.bool.isRequired
  }),
  stage: PropTypes.shape({
    name: PropTypes.string,
    segment: PropTypes.shape({
      id: PropTypes.number.isRequired
    })
  }),
  stravaSegments: PropTypes.shape({
    loading: PropTypes.bool,
    segments: PropTypes.array,
    error: PropTypes.string
  }).isRequired,
  createStage: PropTypes.func.isRequired,
  fetchStravaSegments: PropTypes.func.isRequired,
  setStravaSegment: PropTypes.func.isRequired,
  updateStage: PropTypes.func.isRequired
}

const mapStateToProps = state => {
  return {
    errors: state.errors,
    formState: state.formState,
    stage: state.stage,
    redirectTo: state.redirectTo,
    stravaSegments: state.stravaSegments
  };
}

const mapDispatchToProps = dispatch => ({
  cancelStage: url => dispatch(cancelStage(url)),
  createStage: stage => dispatch(createStage(stage)),
  setStravaSegment: segment => dispatch(setStravaSegment(segment)),
  fetchStravaSegments: () => dispatch(fetchStravaSegments()),
  updateStage: stage => dispatch(updateStage(stage))
})

export default connect(mapStateToProps, mapDispatchToProps)(SegmentStage);
