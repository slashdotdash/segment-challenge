import 'whatwg-fetch'

export const setFormStep = step => ({
  type: 'SET_FORM_STEP',
  step: step
})

export const setStravaSegment = stravaSegment => ({
  type: 'SET_STRAVA_SEGMENT',
  stravaSegment: stravaSegment
})

export const setActivityType = activityType => ({
  type: 'SET_ACTIVITY_TYPE',
  activityType: activityType
})

export const updateStage = stage => ({
  type: 'UPDATE_STAGE',
  stage: stage
})

const dateToLocalISOString = d => {
  let offset = d.getTimezoneOffset();
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), d.getHours(), (d.getMinutes() - offset), d.getSeconds()).toISOString();
}

const redirectTo = url => window.location.replace(url)

export const cancelStage = url => {
  return dispatch => {
    redirectTo(url)
  }
}

export const createStage = stage => {
  return dispatch => {
    dispatch(createStageBegin())

    let {
      challengeUUID,
      stageNumber,
      stravaSegment,
      stageType,
      segmentType,
      activityType,
      name,
      description,
      startDescription,
      endDescription,
      startDate,
      endDate,
      allowPrivateActivities,
      includedActivities,
      hasGoal,
      goal,
      goalUnits,
      singleActivityGoal
    } = stage

    let params = {
      challenge_uuid: challengeUUID,
      stage_number: stageNumber,
      type: stageType,
      name: name,
      description: description,
      start_description: startDescription,
      end_description: endDescription,
      allow_private_activities: allowPrivateActivities,
      included_activity_types: includedActivities
    }

    if (stageType == 'segment') {
      params.stage_type = segmentType
    } else if (stageType == 'activity') {
      params.stage_type = activityType
    }

    if (stravaSegment) {
      params = {
        ...params,
        strava_segment_id: stravaSegment.id
      }
    }

    if (startDate) {
      params = {
        ...params,
        start_date_local: dateToLocalISOString(startDate),
        start_date: startDate.toISOString()
      }
    }

    if (endDate) {
      // Set end date as 23:59:59 on selected day
      endDate = new Date(
        endDate.getFullYear(),
        endDate.getMonth(),
        endDate.getDate(),
        (endDate.getHours() + 24),
        endDate.getMinutes(),
        (endDate.getSeconds() - 1)
      )

      params = {
        ...params,
        end_date_local: dateToLocalISOString(endDate),
        end_date: endDate.toISOString()
      }
    }

    if (hasGoal) {
      params = {
        ...params,
        has_goal: hasGoal,
        goal: goal,
        goal_units: goalUnits,
        single_activity_goal: !!singleActivityGoal
      }
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

    return fetch('/api/stages', options)
      .then(handleErrors)
      .then(res => res.json())
      .then(json => {
        if (json.errors) {
          dispatch(createStageFailure(json.errors))
        } else {
          redirectTo(json.redirect_to);
        }

        return json;
      })
      .catch(error => {
        dispatch(createStageError(error))
      });
  }
}

const createStageBegin = () => ({
  type: 'CREATE_STAGE_BEGIN'
})

const createStageFailure = errors => ({
  type: 'CREATE_STAGE_FAILURE',
  errors: errors
})

const createStageError = error => ({
  type: 'CREATE_STAGE_ERROR',
  error: error
})

export const fetchStravaSegments = () => {
  return dispatch => {
    dispatch(fetchStravaSegmentsBegin())

    const options = {
      method: 'GET',
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      }
    }

    return fetch('/api/athlete/segments/starred', options)
      .then(handleErrors)
      .then(res => res.json())
      .then(json => {
        let segments = json.map(segment => ({
          ...segment,
          id: segment.strava_segment_id,
          activityType: segment.activity_type,
          averageGrade: segment.average_grade,
          distanceInMetres: segment.distance_in_metres,
          maximumGrade: segment.maximum_grade
        }))

        dispatch(fetchStravaSegmentsSuccess(segments));
        return segments;
      })
      .catch(error => dispatch(fetchStravaSegmentsFailure(error)));
  }
}

// Handle HTTP errors since fetch won't
function handleErrors(response) {
  if (response.status === 403) {
    redirectTo(window.location)
    return
  }

  if (!response.ok && response.status !== 422) {
    throw Error(response.statusText);
  }

  return response;
}

const fetchStravaSegmentsBegin = () => ({
  type: 'FETCH_STRAVA_SEGMENTS_BEGIN'
})

const fetchStravaSegmentsSuccess = segments => ({
  type: 'FETCH_STRAVA_SEGMENTS_SUCCESS',
  segments: segments
})

const fetchStravaSegmentsFailure = error => ({
  type: 'FETCH_STRAVA_SEGMENTS_FAILURE',
  error: error
})
