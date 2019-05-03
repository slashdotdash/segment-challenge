import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { updateChallenge } from '../actions'
import CalendarField from '../../form/components/CalendarField'
import InputField from '../../form/components/InputField'
import RadioField from '../../form/components/RadioField'
import MarkdownField from '../../form/components/MarkdownField'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const ChallengeDetails = ({challenge, errors, updateChallenge}) => {
  const {club, name, description, startDate, endDate, restrictedToClubMembers, allowPrivateActivities} = challenge

  return (
    <div>
      <InputField
          label="Name of the challenge"
          value={name}
          error={errorFor(errors, 'name')}
          onChange={name => updateChallenge({name})} />

      <hr />

      <div className="columns">
        <div className="column">
          <CalendarField
              label="Start and end dates"
              placeholder="Click to select the dates"
              startDate={startDate}
              endDate={endDate}
              error={errorFor(errors, 'start_date') || errorFor(errors, 'start_date_local') || errorFor(errors, 'end_date') || errorFor(errors, 'end_date_local')}
              onSelected={dates => updateChallenge(dates)} />
        </div>
        <div className="column content">
          <br />
          <p>
            Your challenge may start before today, but must end in the future.
          </p>
        </div>
      </div>

      <hr />

      <MarkdownField
          label="Describe the challenge"
          value={description}
          placeholder="Provide a description of your challenge for the competitors."
          rowCount={15}
          error={errorFor(errors, 'description')}
          onChange={description => updateChallenge({description})} />

      <hr />

      <div className="columns">
        <div className="column">
          <RadioField
              label="Who can join the challenge?"
              name="restricted_to_club_members"
              values={{'Only club members': true, 'Everyone': false}}
              selectedValue={restrictedToClubMembers}
              error={errorFor(errors, 'restricted_to_club_members')}
              onChange={restrictedToClubMembers => updateChallenge({restrictedToClubMembers})} />
        </div>
        <div className="column content">
          <p>
            You can restrict who can join your challenge to <strong>only</strong> {club && club.name} members or allow <strong>everyone</strong> to join.
          </p>
        </div>
      </div>

      <hr />

      <div className="columns">
        <div className="column">
          <RadioField
              label="Allow private activities?"
              name="allow_private_activities"
              values={{'Yes': true, 'No': false}}
              selectedValue={allowPrivateActivities}
              error={errorFor(errors, 'allow_private_activities')}
              onChange={allowPrivateActivities => updateChallenge({allowPrivateActivities})} />
        </div>
        <div className="column content">
          <p>
            Athletes decide who can see their activities on the <a href="https://www.strava.com/settings/privacy" target="_blank">Strava Privacy Controls</a> page.
            By default a challenge will include activities that are visible to <strong>Everyone</strong> and <strong>Followers</strong>.
          </p>
          <p>
            Allow private activities to include activities where the athlete has restricted who can see to <strong>Only You</strong>.
          </p>
        </div>
      </div>
    </div>
  )
}

ChallengeDetails.propTypes = {
  challenge: PropTypes.shape({
    name: PropTypes.string,
    description: PropTypes.string,
    startDate: PropTypes.instanceOf(Date),
    endDate: PropTypes.instanceOf(Date),
    restrictedToClubMembers: PropTypes.bool,
    allowPrivateActivities: PropTypes.bool
  }).isRequired,
  errors: PropTypes.array,
  updateChallenge: PropTypes.func.isRequired
}

const mapStateToProps = state => {
  return {
    challenge: state.challenge,
    errors: state.errors
  };
}

const mapDispatchToProps = dispatch => ({
  updateChallenge: challenge => dispatch(updateChallenge(challenge))
})

export default connect(mapStateToProps, mapDispatchToProps)(ChallengeDetails);
