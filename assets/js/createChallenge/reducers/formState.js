const formState = (state = {step: 1, loading: false, submitting: false}, action) => {
  switch (action.type) {
    case 'SET_CLUB':
      return {...state, step: 2}

    case 'SET_FORM_STEP':
      return {...state, step: action.step}

    case 'FETCH_STRAVA_CLUBS_BEGIN':
      return {...state, loading: true}

    case 'FETCH_STRAVA_CLUBS_SUCCESS':
      return {...state, loading: false}

    case 'FETCH_STRAVA_CLUBS_FAILURE':
      return {...state, loading: false}

    case 'CREATE_CHALLENGE_BEGIN':
      return {...state, submitting: true}

    case 'CREATE_CHALLENGE_FAILURE':
      return {...state, submitting: false}

    case 'CREATE_CHALLENGE_ERROR':
      return {...state, submitting: false}

    default:
      return state
  }
}

export default formState
