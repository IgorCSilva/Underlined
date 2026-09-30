defmodule ApiWeb.AuthJSON do
  alias ApiWeb.UserJSON

  def session(%{user: user, access_token: access_token}) do
    %{data: %{access_token: access_token, user: UserJSON.data(user)}}
  end

  def session_user(%{user: user}) do
    %{data: UserJSON.data(user)}
  end
end
