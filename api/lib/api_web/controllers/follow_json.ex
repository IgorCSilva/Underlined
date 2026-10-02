defmodule ApiWeb.FollowJSON do
  def show(%{follow: follow}), do: %{data: follow}
end
