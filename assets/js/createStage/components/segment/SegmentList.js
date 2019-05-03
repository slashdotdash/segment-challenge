import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'
import ValidationFailure from '../../../form/components/ValidationFailure'

const Loading = () => (
  <div className="notification">
    <p>Fetching your starred Strava segments ...</p>
  </div>
)

const Level = ({heading, content}) => (
  <div className="level-item has-text-centered">
    <div>
      <p className="heading">{heading}</p>
      <p className="title">{content}</p>
    </div>
  </div>
)

const SegmentValidationWarning = ({error}) => {
  if (error) {
    return (
      <div className="notification is-danger">
        You must select a Strava segment for the stage.
      </div>
    )
  }

  return null
}

const Segment = ({segment, selectedSegment, onSelected}) => {
  const segmentClass = classNames({
    'box': true,
    'is-active': selectedSegment && selectedSegment.id === segment.id
  })

  return (
    <div className={segmentClass}>
      <div className="columns">
        <div className="column">
          <h3 className="title is-5">{segment.name}</h3>
          <h4 className="subtitle is-6">{segment.city}, {segment.state}, {segment.country}</h4>

          <span className="tag">{segment.activityType}</span>
        </div>
        <div className="column">
          <div className="content">
            <nav className="level">
              <Level heading="Distance" content={'' + segment.distanceInMetres + 'metres'} />
              <Level heading="Average grade" content={'' + segment.averageGrade + '%'} />
              <Level heading="Maximum grade" content={'' + segment.maximumGrade + '%'} />
            </nav>
          </div>
        </div>
        <div className="column has-vertically-aligned-content is-2">
           <button className="button is-primary is-outlined is-fullwidth" onClick={() => onSelected(segment)}>
             Select
           </button>
        </div>
      </div>
    </div>
  )
}

const SegmentList = ({loading, segments, selectedSegment, error, onRefresh, onSelected}) => {
  if (loading) {
    return (<Loading />)
  }

  if (segments.length == 0) {
    return (
      <div>
        <div className="notification is-warning">
          <div className="content">
            <p>
              <strong>You don't have any starred Strava segments.</strong>
            </p>

            <p>
              Please <a href="https://www.strava.com/athlete/segments/starred" target="_blank">star the segment on Strava</a> you want to be used for the stage.
            </p>

            <p>Once you've starred the segment on Strava click the button below to refresh.</p>
          </div>
        </div>
        <p>
          <a className="button is-primary" onClick={() => onRefresh()}>Refresh starred Strava segments</a>
        </p>
      </div>
    )
  }

  return (
    <div>
      <SegmentValidationWarning error={error} />

      <p>
        You must <a href="https://www.strava.com/athlete/segments/starred" target="_blank">star any segment on Strava</a> you want to be used as a stage in your challenge.
      </p>

      <br />

      {segments.map(segment => (
        <Segment
            segment={segment}
            selectedSegment={selectedSegment}
            onSelected={onSelected}
            key={segment.id} />
      ))}

      <hr />

      <p>
        <a className="button is-primary" onClick={() => onRefresh()}>Refresh starred Strava segments</a>
      </p>
    </div>
  )
}

SegmentList.propTypes = {
  loading: PropTypes.bool,
  segments: PropTypes.array,
  selectedSegment: PropTypes.shape({
    id: PropTypes.number.isRequired
  }),
  error: PropTypes.string,
  onRefresh: PropTypes.func.isRequired,
  onSelected: PropTypes.func.isRequired
}

export default SegmentList;
