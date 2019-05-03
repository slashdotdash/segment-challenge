defimpl Commanded.Serialization.JsonDecoder, for: SegmentChallenge.Events.MembersJoinedClub do
  alias SegmentChallenge.Events.MembersJoinedClub
  alias SegmentChallenge.Events.MembersJoinedClub.Member

  def decode(%MembersJoinedClub{members: members} = event) do
    %MembersJoinedClub{event |
      members: map_to_member(members),
    }
  end

  defp map_to_member(members) do
    Enum.map(members, fn member -> struct(Member, member) end)
  end
end
