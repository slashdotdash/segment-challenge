import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { setActivityType, cancelStage, createStage, updateStage } from '../actions'
import classNames from 'classnames'
import FormStep from '../../form/components/FormStep'
import IncludedActivities from '../components/activity/IncludedActivities'
import ActivityType from '../components/activity/ActivityType'
import StageGoal from '../components/activity/StageGoal'
import RadioField from '../../form/components/RadioField'
import SelectField from '../../form/components/SelectField'
import StageDetails from './StageDetails'
import SubmitButton from '../../form/components/SubmitButton'
import TextAreaField from '../../form/components/TextAreaField'
import ValidationFailure from '../../form/components/ValidationFailure'

const errorFor = (errors, field) => {
  const error = errors.find(error => error.name == field)
  if (error) {
    return error.message
  }
}

const ActivityStage = ({ errors, formState, redirectTo, stage, setActivityType, createStage, updateStage }) => {
  const {
    activityType,
    allowPrivateActivities,
    includedActivities,
    hasGoal,
    goal,
    goalUnits,
    singleActivityGoal,
    unitsOfMeasure
  } = stage

  return (
    <div>
      <FormStep step={2} currentStep={formState.step}>
        <h1 className="title">Stage activity type</h1>
        <h2 className="subtitle">Select the type of activity to record</h2>

        <ActivityType activityType={activityType} onChange={setActivityType} />
      </FormStep>

      <FormStep step={3} currentStep={formState.step}>
        <h1 className="title">Create stage</h1>

        <StageDetails />

        <hr />

        <div className="columns">
          <div className="column">
            <div className="field">
              <label className="label">Which activities are included in the stage?</label>

              <IncludedActivities
                  includedActivities={includedActivities}
                  error={errorFor(errors, 'included_activity_types')}
                  onChange={includedActivities => updateStage({includedActivities})} />
            </div>
          </div>
          <div className="column content">
            <p>
              You can restrict the stage to one or more activity types.
              Only selected activities will be included in the stage.
            </p>
          </div>
        </div>

        <hr />

        <div className="columns">
          <div className="column">
            <RadioField
                label="Allow private activities?"
                name="allow_private_activities"
                values={{'Yes': true, 'No': false}}
                selectedValue={allowPrivateActivities}
                error={errorFor(errors, 'allow_private_activities')}
                onChange={allowPrivateActivities => updateStage({allowPrivateActivities})} />
          </div>
          <div className="column content">
            <p>
              Athletes decide who can see their activities on the <a href="https://www.strava.com/settings/privacy" target="_blank">Strava Privacy Controls</a> page.
              By default a stage will include activities that are visible to <strong>Everyone</strong> and <strong>Followers</strong>.
            </p>
            <p>
              Allow private activities to include activities where the athlete has restricted who can see to <strong>Only You</strong>.
            </p>
          </div>
        </div>

        <hr />

        <div className="columns">
          <div className="column">
            <RadioField
                label="Does the stage have a goal?"
                name="has_goal"
                values={{'Yes': true, 'No': false}}
                selectedValue={hasGoal}
                error={errorFor(errors, 'has_goal')}
                onChange={hasGoal => updateStage({hasGoal})} />

            <StageGoal
                unitsOfMeasure={unitsOfMeasure}
                hasGoal={hasGoal}
                goal={goal}
                units={goalUnits}
                singleActivityGoal={singleActivityGoal}
                errors={errors}
                onChange={(goal, units, singleActivityGoal) => updateStage({goal: goal, goalUnits: units, singleActivityGoal: singleActivityGoal})} />
          </div>
          <div className="column content">
            <p>
              A goal can be used to motivate competitors to reach a target distance or time, such as ride 1,000 miles in a month.
            </p>
            <p>
              Competitors will be awarded a badge when they achieve the stage goal.
            </p>
            <p>
              A single activity goal will require competitors to achieve the target distance in one activity,
              such as 100 miles in a single ride, 10km in one run.
            </p>
          </div>
        </div>

        <hr />

        <SubmitButton
            label="Create stage"
            disabled={formState.submitting}
            loading={formState.loading}
            onSubmit={() => createStage(stage)}
            onCancel={() => cancelStage(redirectTo)} />
      </FormStep>
    </div>
  )
}

ActivityStage.propTypes = {
  errors: PropTypes.array,
  formState: PropTypes.shape({
    loading: PropTypes.bool.isRequired,
    submitting: PropTypes.bool.isRequired
  }),
  stage: PropTypes.shape({
    name: PropTypes.string,
    includedActivities: PropTypes.array,
    hasGoal: PropTypes.bool,
    goal: PropTypes.string,
    goalUnits: PropTypes.string,
    singleActivityGoal: PropTypes.bool,
    unitsOfMeasure: PropTypes.object
  }),
  createStage: PropTypes.func.isRequired,
  updateStage: PropTypes.func.isRequired
}

const mapStateToProps = state => {
  return {
    errors: state.errors,
    formState: state.formState,
    redirectTo: state.redirectTo,
    stage: state.stage
  };
}

const mapDispatchToProps = dispatch => ({
  cancelStage: url => dispatch(cancelStage(url)),
  createStage: stage => dispatch(createStage(stage)),
  setActivityType: activityType => dispatch(setActivityType(activityType)),
  updateStage: stage => dispatch(updateStage(stage))
})

export default connect(mapStateToProps, mapDispatchToProps)(ActivityStage);
