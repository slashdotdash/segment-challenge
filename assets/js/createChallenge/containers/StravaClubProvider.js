import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { fetchStravaClubs, refreshStravaClubs, setClub } from '../actions'
import ClubList from '../components/ClubList'

class StravaClubProvider extends React.Component {
  componentDidMount() {
    const {isLoaded, fetchStravaClubs} = this.props

    if (!isLoaded) {
      fetchStravaClubs()
    }
  }

  render() {
    const {isLoaded, stravaClubs, refreshStravaClubs, setClub} = this.props

    if (isLoaded) {
      return (
        <ClubList stravaClubs={stravaClubs} onSelect={setClub} onRefresh={refreshStravaClubs} />
      )
    }

    return (
      <div className="notification">
        <p>
          Fetching your Strava clubs &hellip;
        </p>
      </div>
    )
  }
}

StravaClubProvider.propTypes = {
  isLoaded: PropTypes.bool.isRequired,
  stravaClubs: PropTypes.array,
  fetchStravaClubs: PropTypes.func.isRequired,
  setClub: PropTypes.func.isRequired
}

const mapStateToProps = state => {
  return {
    isLoaded: state.stravaClubs.loaded,
    stravaClubs: state.stravaClubs.clubs
  }
}

const mapDispatchToProps = dispatch => ({
  fetchStravaClubs: () => dispatch(fetchStravaClubs()),
  refreshStravaClubs: () => dispatch(refreshStravaClubs()),
  setClub: club => dispatch(setClub(club))
})

export default connect(mapStateToProps, mapDispatchToProps)(StravaClubProvider);
