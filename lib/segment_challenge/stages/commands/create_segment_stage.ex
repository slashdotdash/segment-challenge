defmodule SegmentChallenge.Stages.Stage.Commands.CreateSegmentStage do
  alias SegmentChallenge.Stages.Stage.Commands.CreateSegmentStage
  alias SegmentChallenge.Stages.Stage.Commands.CreateSegmentStage.Segment
  alias SegmentChallenge.Challenges.Services.UrlSlugs.UniqueSlugger

  defstruct [
    :stage_uuid,
    :challenge_uuid,
    :stage_number,
    :strava_segment_id,
    :stage_type,
    :name,
    :description,
    :start_date,
    :start_date_local,
    :end_date,
    :end_date_local,
    :allow_private_activities,
    :points_adjustment,
    :start_description,
    :end_description,
    :created_by_athlete_uuid,
    visible: false,
    slugger: &UniqueSlugger.slugify/3,
    strava_segment_factory: &Segment.build/1
  ]

  defmodule Segment do
    alias SegmentChallenge.Strava.StravaAccess
    alias SegmentChallenge.Strava.Gateway, as: StravaGateway

    defstruct [
      :strava_segment_id,
      :activity_type,
      :distance_in_metres,
      :average_grade,
      :maximum_grade,
      :elevation_high,
      :elevation_low,
      :start_latlng,
      :end_latlng,
      :climb_category,
      :city,
      :state,
      :country,
      :total_elevation_gain,
      :map_polyline
    ]

    def build(%CreateSegmentStage{} = command) do
      %CreateSegmentStage{
        created_by_athlete_uuid: athlete_uuid,
        strava_segment_id: strava_segment_id
      } = command

      with {:ok, access_token, refresh_token} <- StravaAccess.get_access_token(athlete_uuid),
           client <- StravaGateway.build_client(athlete_uuid, access_token, refresh_token),
           {:ok, %Strava.DetailedSegment{} = segment} <-
             StravaGateway.get_segment(client, strava_segment_id),
           %Segment{} = segment <- new_from_strava(segment) do
        if Vex.valid?(segment) do
          {:ok, segment}
        else
          {:error, {:validation_failure, Vex.errors(segment)}}
        end
      end
    end

    defp new_from_strava(%Strava.DetailedSegment{} = segment) do
      %Strava.DetailedSegment{
        id: strava_segment_id,
        activity_type: activity_type,
        distance: distance_in_metres,
        average_grade: average_grade,
        maximum_grade: maximum_grade,
        elevation_high: elevation_high,
        elevation_low: elevation_low,
        start_latlng: start_latlng,
        end_latlng: end_latlng,
        climb_category: climb_category,
        city: city,
        state: state,
        country: country,
        total_elevation_gain: total_elevation_gain,
        map: %Strava.PolylineMap{polyline: map_polyline}
      } = segment

      %Segment{
        strava_segment_id: strava_segment_id,
        activity_type: activity_type,
        distance_in_metres: distance_in_metres,
        average_grade: average_grade,
        maximum_grade: maximum_grade,
        elevation_high: elevation_high,
        elevation_low: elevation_low,
        start_latlng: start_latlng,
        end_latlng: end_latlng,
        climb_category: climb_category,
        city: city,
        state: state,
        country: country,
        total_elevation_gain: total_elevation_gain,
        map_polyline: map_polyline
      }
    end

    use ExConstructor
    use Vex.Struct

    validates(:strava_segment_id, presence: true, by: &is_integer/1)
    validates(:distance_in_metres, presence: true, by: &is_float/1)
    validates(:average_grade, presence: true, by: &is_float/1)
    validates(:maximum_grade, presence: true, by: &is_float/1)
    validates(:elevation_high, presence: true, by: &is_float/1)
    validates(:elevation_low, presence: true, by: &is_float/1)
    validates(:start_latlng, presence: true, by: &is_list/1)
    validates(:end_latlng, presence: true, by: &is_list/1)
    validates(:climb_category, presence: true, by: &is_integer/1)
    validates(:city, string: true)
    validates(:state, string: true)
    validates(:country, string: true)
    validates(:total_elevation_gain, presence: true, by: &is_float/1)
    validates(:map_polyline, string: true)
  end

  use ExConstructor
  use Vex.Struct

  alias SegmentChallenge.Stages.Validators.StageNumber

  validates(:stage_uuid, uuid: true)
  validates(:challenge_uuid, uuid: true)
  validates(:stage_number, presence: true, by: &StageNumber.validate/2)
  validates(:strava_segment_id, presence: true, by: &is_integer/1)
  validates(:stage_type, presence: true, stage_type: true)
  validates(:name, presence: true, string: true)
  validates(:description, string: true)
  validates(:start_date, presence: true, naivedatetime: true)
  validates(:start_date_local, presence: true, naivedatetime: true)
  validates(:end_date, presence: true, naivedatetime: true, futuredate: true)
  validates(:end_date_local, presence: true, naivedatetime: true)

  validates(:allow_private_activities,
    by: [function: &is_boolean/1, allow_nil: false, message: "must be present"]
  )

  validates(:points_adjustment, pointsadjustment: true)
  validates(:start_description, string: true)
  validates(:end_description, string: true)
  validates(:created_by_athlete_uuid, uuid: true)
  validates(:visible, by: [function: &is_boolean/1, allow_nil: false])
  validates(:slugger, by: &is_function/1)
end
