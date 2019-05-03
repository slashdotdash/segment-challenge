const stage = (state = [], action) => {
  switch (action.type) {
    case 'CREATE_STAGE_BEGIN':
      return []

    case 'CREATE_STAGE_FAILURE':
      return action.errors

    default:
      return state
  }
}

export default stage
