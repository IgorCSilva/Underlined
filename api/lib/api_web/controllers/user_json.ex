defmodule ApiWeb.UserJSON do
  @moduledoc """
  Renders either the pure Api.Domain.User or the Postgres user entity, since
  callers are mid-migration from one to the other.
  """

  def show(%{user: user}), do: %{data: data(user)}

  def data(user) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      bio: user.bio,
      avatar_url: user.avatar_url,
      confirmed: user.confirmed_at != nil,
      followed_by_user: user.followed_by_user
    }
  end
end
