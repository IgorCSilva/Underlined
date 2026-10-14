defmodule ApiWeb.ClubPostController do
  use ApiWeb, :controller

  alias Api.Adapters.Clubs
  alias Api.Usecases.Club.CreateClubPost.CreateClubPostUsecaseDto
  alias Api.Usecases.Club.ListClubPosts.ListClubPostsUsecaseDto
  alias Api.Usecases.Club.RevealClubPost.RevealClubPostUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"club_id" => club_id}) do
    with {:ok, posts} <-
           Clubs.list_club_posts(%ListClubPostsUsecaseDto{
             club_id: club_id,
             current_user: current_user(conn)
           }) do
      render(conn, :index, posts: posts)
    end
  end

  def reveal(conn, %{"id" => id}) do
    with {:ok, post} <- Clubs.reveal_club_post(%RevealClubPostUsecaseDto{post_id: id}) do
      render(conn, :show, post: post)
    end
  end

  def create(conn, %{"club_id" => club_id, "post" => post_params}) do
    with {:ok, post} <-
           Clubs.create_club_post(%CreateClubPostUsecaseDto{
             user: current_user(conn),
             club_id: club_id,
             attrs: post_params
           }) do
      conn
      |> put_status(:created)
      |> render(:show, post: post)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
