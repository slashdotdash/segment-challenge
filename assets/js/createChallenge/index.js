import React from 'react'
import { render } from 'react-dom'
import { createStore, applyMiddleware, compose } from 'redux'
import thunk from "redux-thunk"
import { Provider } from 'react-redux'
import CreateChallenge from './containers/CreateChallenge'
import rootReducer from './reducers'

const normaliseChallengeType = type => {
  switch (type) {
    case 'segment':
    case 'segment-challenge':
      return 'segment'

    case 'activity':
    case 'activity-challenge':
      return 'activity'

    case 'virtual-race':
      return 'race'
  }
}

const initialState = config => {
  const {challengeType, redirectTo} = config

  return {
    challenge: {
      name: '',
      challengeType: normaliseChallengeType(challengeType),
      includedActivities: [],
      unitsOfMeasure: []
    },
    redirectTo: redirectTo
  }
}

const renderCreateChallenge = (element, config) => {
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  const store = createStore(rootReducer, initialState(config), composeEnhancers(
    applyMiddleware(thunk),
  ))

  render(
    <Provider store={store}>
      <CreateChallenge />
    </Provider>,
    document.getElementById(element)
  )
}

window.SegmentChallenge = window.SegmentChallenge || {};
window.SegmentChallenge.renderCreateChallenge = renderCreateChallenge;

export default renderCreateChallenge
