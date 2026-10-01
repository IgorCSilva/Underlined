defmodule ApiWeb.LikeController do
  use ApiWeb, :controller

  alias Api.Posts

  action_fallback ApiWeb.FallbackController

  def create(conn, %{"post_id" => post_id}) do
    with {:ok, like} <- Posts.like_post(current_user(conn), post_id) do
      render(conn, :show, like: like)
    end
  end

  def delete(conn, %{"post_id" => post_id}) do
    with {:ok, like} <- Posts.unlike_post(current_user(conn), post_id) do
      render(conn, :show, like: like)
    end
  end

  defp current_user(conn), do: Api.Accounts.Guardian.Plug.current_resource(conn)
end
