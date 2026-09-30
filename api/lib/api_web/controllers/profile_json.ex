defmodule ApiWeb.ProfileJSON do
  alias ApiWeb.UserJSON

  def show(%{user: user}), do: %{data: UserJSON.data(user)}
end
