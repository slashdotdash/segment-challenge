import React from 'react'
import { render } from 'react-dom'
import { createStore, applyMiddleware, compose } from 'redux'
import thunk from "redux-thunk"
import { Provider } from 'react-redux'
import CreateStage from './containers/CreateStage'
import rootReducer from './reducers'

const initialState = config => {
  let stage = {
    ...config,
    name: '',
    includedActivities: [],
    unitsOfMeasure: {}
  }

  if (config.minStartDate) {
    stage.minStartDate = new Date(config.minStartDate)
  }

  if (config.maxEndDate) {
    stage.maxEndDate = new Date(config.maxEndDate)
  }

  return {
    stage: stage,
    redirectTo: config.redirectTo
  }
}

const renderCreateStage = (element, config) => {
  const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;

  const store = createStore(rootReducer, initialState(config), composeEnhancers(
    applyMiddleware(thunk),
  ))

  render(
    <Provider store={store}>
      <CreateStage />
    </Provider>,
    document.getElementById(element)
  )
}

window.SegmentChallenge = window.SegmentChallenge || {};
window.SegmentChallenge.renderCreateStage = renderCreateStage;

export default renderCreateStage
