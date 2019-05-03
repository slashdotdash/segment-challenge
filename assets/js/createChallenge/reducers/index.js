import { combineReducers } from 'redux'
import errors from './errors'
import formState from './formState'
import challenge from './challenge'
import stravaClubs from './stravaClubs'

const redirectTo = (state = '', action) => {
  return state
}

export default combineReducers({
  errors,
  formState,
  redirectTo,
  challenge,
  stravaClubs
})
