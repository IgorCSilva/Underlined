defmodule ApiWeb.LikeController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.Like.LikePost.LikePostUsecaseDto
  alias Api.Usecases.Like.UnlikePost.UnlikePostUsecaseDto

  action_fallback ApiWeb.FallbackController

  def create(conn, %{"post_id" => post_id}) do
    with {:ok, like} <-
           Posts.like_post(%LikePostUsecaseDto{user: current_user(conn), post_id: post_id}) do
      render(conn, :show, like: like)
    end
  end

  def delete(conn, %{"post_id" => post_id}) do
    with {:ok, like} <-
           Posts.unlike_post(%UnlikePostUsecaseDto{user: current_user(conn), post_id: post_id}) do
      render(conn, :show, like: like)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
