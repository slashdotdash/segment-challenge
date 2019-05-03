const initialState = {
  clubs: [],
  loaded: false,
  loading: false,
  error: null
};

const stravaClubs = (state = initialState, action) => {
  switch (action.type) {
    case 'FETCH_STRAVA_CLUBS_BEGIN':
      return {...state, loaded: false, loading: true, error: null, clubs: []}

    case 'FETCH_STRAVA_CLUBS_SUCCESS':
      return {...state, loaded: true, loading: false, error: null, clubs: action.clubs}

    case 'FETCH_STRAVA_CLUBS_FAILURE':
      return {...state, loaded: false, loading: false, error: action.error, clubs: []}

    default:
      return state
  }
}

export default stravaClubs
