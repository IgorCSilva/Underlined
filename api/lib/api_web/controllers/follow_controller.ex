defmodule ApiWeb.FollowController do
  use ApiWeb, :controller

  alias Api.Adapters.Accounts
  alias Api.Usecases.Follow.FollowUser.FollowUserUsecaseDto
  alias Api.Usecases.Follow.UnfollowUser.UnfollowUserUsecaseDto

  action_fallback ApiWeb.FallbackController

  def create(conn, %{"id" => followee_id}) do
    with {:ok, follow} <-
           Accounts.follow_user(%FollowUserUsecaseDto{
             follower: current_user(conn),
             followee_id: followee_id
           }) do
      render(conn, :show, follow: follow)
    end
  end

  def delete(conn, %{"id" => followee_id}) do
    with {:ok, follow} <-
           Accounts.unfollow_user(%UnfollowUserUsecaseDto{
             follower: current_user(conn),
             followee_id: followee_id
           }) do
      render(conn, :show, follow: follow)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
