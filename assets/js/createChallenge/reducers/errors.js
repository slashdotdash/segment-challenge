const stage = (state = [], action) => {
  switch (action.type) {
    case 'CREATE_CHALLENGE_BEGIN':
      return []

    case 'CREATE_CHALLENGE_FAILURE':
      return action.errors

    default:
      return state
  }
}

export default stage
