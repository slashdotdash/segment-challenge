import moment from 'moment'

const buildStages = challenge => {
  const {description, startDate, endDate, hasGoal, goalRecurrence} = challenge

  const challengeStartDate = moment(startDate)
  const challengeEndDate = moment(endDate)

  let stages = []
  let stageNumber = 1

  if (hasGoal && goalRecurrence && goalRecurrence != 'none') {
    let stageStartDate = moment(startDate)
    let stageEndDate = addInterval(moment(startDate), goalRecurrence).subtract(1, 'd')

    while (!stageStartDate.isAfter(challengeEndDate) && stageNumber <= 10000) {
      if (stageEndDate.isAfter(challengeEndDate)) {
        stageEndDate = challengeEndDate
      }

      let name = stageName(stageNumber, stageStartDate, goalRecurrence)

      stages.push({
        stageNumber: stageNumber,
        name: name,
        description: challenge.name + ' -- ' + name,
        startDate: stageStartDate.toDate(),
        endDate: stageEndDate.toDate()
      })

      stageNumber += 1
      stageStartDate = addInterval(stageStartDate, goalRecurrence)
      stageEndDate = addInterval(stageEndDate, goalRecurrence)
    }
  } else {
    stages.push({
      stageNumber: 1,
      name: 'Stage 1',
      description: description,
      startDate: startDate,
      endDate: endDate
    })
  }

  return stages
}

const endOfMonth = moment => atMidday(moment.clone().endOf('month'))
const atMidday = moment => moment.clone().set({'hour': 12, 'minute': 0, 'seconds': 0, 'milliseconds': 0})

const addInterval = (moment, recurrence) => {
  if (recurrence == 'day') {
    return moment.clone().add(1, 'd')
  }

  if (recurrence == 'week') {
    return moment.clone().add(7, 'd')
  }

  if (recurrence == 'month') {
    // If current date is end of month, make the future date at the end of the month
    if (atMidday(moment).isSame(endOfMonth(moment))) {
      return endOfMonth(moment.clone().add(1, 'M'))
    }

    return moment.clone().add(1, 'M')
  }
}

const stageName = (stageNumber, startDate, interval) => {
  if (interval == 'day') {
    return 'Day ' + stageNumber
  }

  if (interval == 'week') {
    return 'Week ' + stageNumber
  }

  if (interval == 'month') {
    return moment(startDate).format('MMMM YYYY')  // e.g. 'January 2019'
  }

  return 'Stage ' + stageNumber
}

const challenge = (state = {}, action) => {
  switch (action.type) {
    case 'SET_CLUB':
      return {
        ...state,
        club: action.club
      }

    case 'UPDATE_CHALLENGE':
      state = {
        ...state,
        ...action.challenge
      }

      const {startDate, endDate, hasGoal, goalRecurrence} = state

      if (startDate && endDate) {
        state.stages = buildStages(state)
      } else {
        state.stages = null
      }

      return state

    default:
      return state
  }
}

export default challenge
