const initialState = {
  segments: [],
  loaded: false,
  loading: false,
  error: null
};

const stravaSegments = (state = initialState, action) => {
  switch (action.type) {
    case 'FETCH_STRAVA_SEGMENTS_BEGIN':
      return {...state, loaded: false, loading: true, error: null, segments: []}

    case 'FETCH_STRAVA_SEGMENTS_SUCCESS':
      return {...state, loaded: true, loading: false, error: null, segments: action.segments}

    case 'FETCH_STRAVA_SEGMENTS_FAILURE':
      return {...state, loaded: false, loading: false, error: action.error, segments: []}

    default:
      return state
  }
}

export default stravaSegments
