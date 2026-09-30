defmodule ApiWeb.UserJSON do
  alias Api.Accounts.User

  def show(%{user: user}), do: %{data: data(user)}

  def data(%User{} = user) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      bio: user.bio,
      avatar_url: user.avatar_url,
      confirmed: User.confirmed?(user)
    }
  end
end
