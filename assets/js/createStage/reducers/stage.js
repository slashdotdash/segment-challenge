const unitsOfMeasure = activityType => {
  switch (activityType) {
    case 'distance':
    case 'elevation':
      return {
        'Feet': 'feet',
        'Miles': 'miles',
        'Metres': 'metres',
        'Kilometres': 'kilometres'
      }

    case 'duration':
      return {
        'Seconds': 'seconds',
        'Minutes': 'minutes',
        'Hours': 'hours',
        'Days': 'days'
      }

    default:
      return {}
  }
}

const stage = (state = {}, action) => {
  switch (action.type) {
    case 'SET_STRAVA_SEGMENT':
      if (!state.name || state.stravaSegment && state.stravaSegment.name == state.name) {
        state = {...state, name: action.stravaSegment.name}
      }

      return {...state, stravaSegment: action.stravaSegment}

    case 'SET_ACTIVITY_TYPE':
      return {
        ...state,
        activityType: action.activityType,
        unitsOfMeasure: unitsOfMeasure(action.activityType)
      }

    case 'UPDATE_STAGE':
      return {
        ...state,
        ...action.stage
      }

    default:
      return state
  }
}

export default stage
