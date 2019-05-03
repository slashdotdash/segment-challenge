import 'whatwg-fetch'

export const setFormStep = step => ({
  type: 'SET_FORM_STEP',
  step: step
})

export const setClub = club => ({
  type: 'SET_CLUB',
  club: club
})

export const updateChallenge = challenge => ({
  type: 'UPDATE_CHALLENGE',
  challenge: challenge
})

const dateToLocalISOString = d => {
  let offset = d.getTimezoneOffset()
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), (d.getMinutes() - offset), d.getSeconds()).toISOString()
}

const redirectTo = url => window.location.replace(url)

export const cancelChallenge = url => {
  return dispatch => {
    redirectTo(url)
  }
}

const buildStage = stage => {
  const {stageNumber, name, description, startDate, endDate} = stage

  let params = {
    stageNumber: stageNumber,
    name: name,
    description: description
  }

  params = includeStartEndDates(params, startDate, endDate)

  return params
}

const toEndDate = endDate => new Date(
  endDate.getFullYear(),
  endDate.getMonth(),
  endDate.getDate(),
  (endDate.getHours() + 24),
  endDate.getMinutes(),
  (endDate.getSeconds() - 1)
)

const includeStartEndDates = (params, startDate, endDate) => {
  if (startDate) {
    params = {
      ...params,
      start_date_local: dateToLocalISOString(startDate),
      start_date: startDate.toISOString()
    }
  }

  if (endDate) {
    // Set end date as 23:59:59 on selected day
    endDate = toEndDate(endDate)

    params = {
      ...params,
      end_date_local: dateToLocalISOString(endDate),
      end_date: endDate.toISOString()
    }
  }

  return params
}

export const createChallenge = challenge => {
  return dispatch => {
    dispatch(createChallengeBegin())

    let {
      challengeType,
      club,
      name,
      description,
      startDate,
      endDate,
      restrictedToClubMembers,
      allowPrivateActivities,
      activityType,
      includedActivity,
      includedActivities,
      accumulateActivities,
      hasGoal,
      goal,
      goalUnits,
      goalRecurrence,
      stages
    } = challenge

    let params = {
      name: name,
      description: description,
      restricted_to_club_members: restrictedToClubMembers,
      allow_private_activities: allowPrivateActivities,
      accumulate_activities: accumulateActivities
    }

    if (club) {
      params = {
        ...params,
        hosted_by_club_uuid: club.id
      }
    }

    params = includeStartEndDates(params, startDate, endDate)

    switch (challengeType) {
      case 'activity':
        params.challenge_type = activityType
        params.included_activity_types = includedActivities
        params.has_goal = hasGoal

        if (hasGoal) {
          params = {
            ...params,
            goal: goal,
            goal_units: goalUnits,
            goal_recurrence: goalRecurrence
          }
        }

        if (stages) {
          params.stages = stages.map(buildStage)
        }

        break;

      case 'race':
        params = {
          ...params,
          challenge_type: 'race',
          included_activity_types: includedActivity ? [includedActivity] : [],
          accumulate_activities: false,
          has_goal: true,
          goal: goal,
          goal_units: goalUnits,
          goal_recurrence: 'none'
        }
        break;

      case 'segment':
        params.challenge_type = 'segment'
        break
    }

    const options = {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(params)
    }

    return fetch('/api/challenges', options)
      .then(handleErrors)
      .then(res => res.json())
      .then(json => {
        if (json.errors) {
          dispatch(createChallengeFailure(json.errors))
        } else {
          redirectTo(json.redirect_to)
        }

        return json
      })
      .catch(error => {
        dispatch(createChallengeError(error))
      })
  }
}

const createChallengeBegin = () => ({
  type: 'CREATE_CHALLENGE_BEGIN'
})

const createChallengeFailure = errors => ({
  type: 'CREATE_CHALLENGE_FAILURE',
  errors: errors
})

const createChallengeError = error => ({
  type: 'CREATE_CHALLENGE_ERROR',
  error: error
})

export const fetchStravaClubs = () => {
  return dispatch => {
    dispatch(fetchStravaClubsBegin())

    const options = {
      method: 'GET',
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }
    }

    return fetch('/api/athlete/clubs', options)
      .then(handleErrors)
      .then(res => res.json())
      .then(json => {
        let clubs = json.map(club => ({
          ...club,
          id: club.club_uuid
        }))

        dispatch(fetchStravaClubsSuccess(clubs))
        return clubs
      })
      .catch(error => dispatch(fetchStravaClubsFailure(error)))
  }
}

export const refreshStravaClubs = () => {
  return dispatch => {
    dispatch(fetchStravaClubsBegin())

    const options = {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }
    }

    return fetch('/api/athlete/clubs', options)
      .then(handleErrors)
      .then(res => res.json())
      .then(json => {
        let clubs = json.map(club => ({
          ...club,
          id: club.club_uuid
        }))

        dispatch(fetchStravaClubsSuccess(clubs))
        return clubs
      })
      .catch(error => dispatch(fetchStravaClubsFailure(error)))
  }
}

// Handle HTTP errors since fetch won't
function handleErrors(response) {
  if (!response.ok && response.status !== 422) {
    throw Error(response.statusText)
  }

  return response
}

const fetchStravaClubsBegin = () => ({
  type: 'FETCH_STRAVA_CLUBS_BEGIN'
})

const fetchStravaClubsSuccess = clubs => ({
  type: 'FETCH_STRAVA_CLUBS_SUCCESS',
  clubs: clubs
})

const fetchStravaClubsFailure = error => ({
  type: 'FETCH_STRAVA_CLUBS_FAILURE',
  error: error
})
