const formState = (state = {step: 1, loading: false, submitting: false}, action) => {
  switch (action.type) {
    case 'SET_STRAVA_SEGMENT':
      return {...state, step: 2}

    case 'SET_ACTIVITY_TYPE':
      return {...state, step: 2}

    case 'SET_FORM_STEP':
      return {...state, step: action.step}

    case 'FETCH_STRAVA_SEGMENTS_BEGIN':
      return {...state, loading: true}

    case 'FETCH_STRAVA_SEGMENTS_SUCCESS':
      return {...state, loading: false}

    case 'FETCH_STRAVA_SEGMENTS_FAILURE':
      return {...state, loading: false}

    case 'CREATE_STAGE_BEGIN':
      return {...state, submitting: true}

    case 'CREATE_STAGE_FAILURE':
      return {...state, submitting: false}

    case 'CREATE_STAGE_ERROR':
      return {...state, submitting: false}

    default:
      return state
  }
}

export default formState
