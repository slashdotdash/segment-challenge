import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'
import ValidationFailure from '../../form/components/ValidationFailure'

const Level = ({heading, content}) => (
  <div className="level-item has-text-centered">
    <div>
      <p className="heading">{heading}</p>
      <p className="title">{content}</p>
    </div>
  </div>
)

const Club = ({club, selectedClub, onSelect}) => {
  const clubClass = classNames({
    'box': true,
    'is-active': selectedClub && selectedClub.id === club.id
  })

  return (
    <div className={clubClass}>
      <div className="columns">
        <div className="column">
          <article className="media">
            <figure className="media-left">
              <p className="image is-64x64">
                <img src={club.profile} />
              </p>
            </figure>

            <div className="media-content">
              <div className="content">
                <p>
                  <strong>{club.name}</strong><br />
                  <small>{club.city}, {club.state}, {club.country}</small><br />
                  {club.description}
                </p>
              </div>
            </div>
          </article>
        </div>
        <div className="column has-vertically-aligned-content is-2">
           <button className="button is-primary is-outlined is-fullwidth" onClick={() => onSelect(club)}>
             Select
           </button>
        </div>
      </div>
    </div>
  )
}

const ClubList = ({stravaClubs, selectedClub, onSelect, onRefresh}) => (
  <div>
    {stravaClubs.map(club => (
      <Club
          club={club}
          selectedClub={selectedClub}
          onSelect={onSelect}
          key={club.id} />
    ))}

    <hr />

    <p>
      <a className="button is-primary is-outlined" onClick={() => onRefresh()}>Refresh Strava clubs</a>
      <a className="button is-link" href="https://www.strava.com/clubs/new" target="_blank">Create a new Strava club</a>
    </p>
  </div>
)

ClubList.propTypes = {
  stravaClubs: PropTypes.array.isRequired,
  selectedClub: PropTypes.object,
  onSelect: PropTypes.func.isRequired,
  onRefresh: PropTypes.func.isRequired
}

export default ClubList
