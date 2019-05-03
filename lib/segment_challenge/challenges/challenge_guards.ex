defmodule SegmentChallenge.Challenges.ChallengeGuards do
  defguard is_activity_challenge(challenge_type)
           when challenge_type in ["distance", "duration", "elevation"]

  defguard is_segment_challenge(challenge_type) when challenge_type == "segment"

  defguard is_virtual_race(challenge_type) when challenge_type == "race"
end
