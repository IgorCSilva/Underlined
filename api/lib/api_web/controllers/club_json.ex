defmodule ApiWeb.ClubJSON do
  alias Api.Domain.Club
  alias ApiWeb.BookJSON

  def index(%{clubs: clubs}), do: %{data: Enum.map(clubs, &data/1)}

  def show(%{club: club}), do: %{data: data(club)}

  def members(%{members: members}), do: %{data: Enum.map(members, &user_data/1)}

  def membership(%{result: result}), do: %{data: result}

  def data(%Club{} = club) do
    %{
      id: club.id,
      name: club.name,
      description: club.description,
      book: BookJSON.data(club.book),
      creator: user_data(club.creator),
      member_count: club.member_count,
      members_preview: Enum.map(club.members_preview, &user_data/1),
      joined_by_user: club.joined_by_user,
      inserted_at: club.inserted_at
    }
  end

  defp user_data(user), do: %{id: user.id, name: user.name, avatar_url: user.avatar_url}
end
