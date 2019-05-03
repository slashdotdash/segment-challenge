import { combineReducers } from 'redux'
import errors from './errors'
import formState from './formState'
import stage from './stage'
import stravaSegments from './stravaSegments'

const redirectTo = (state = '', action) => {
  return state
}

export default combineReducers({
  errors,
  formState,
  redirectTo,
  stage,
  stravaSegments
})
