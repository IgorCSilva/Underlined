defmodule ApiWeb.ClubCommentController do
  use ApiWeb, :controller

  alias Api.Adapters.Clubs
  alias Api.Usecases.Club.CreateClubComment.CreateClubCommentUsecaseDto
  alias Api.Usecases.Club.ListClubComments.ListClubCommentsUsecaseDto
  alias Api.Usecases.Club.UpdateClubComment.UpdateClubCommentUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"club_post_id" => club_post_id}) do
    comments = Clubs.list_club_comments(%ListClubCommentsUsecaseDto{club_post_id: club_post_id})
    render(conn, :index, comments: comments)
  end

  def create(conn, %{"club_post_id" => club_post_id, "comment" => comment_params}) do
    with {:ok, comment} <-
           Clubs.create_club_comment(%CreateClubCommentUsecaseDto{
             user: current_user(conn),
             club_post_id: club_post_id,
             attrs: comment_params
           }) do
      conn
      |> put_status(:created)
      |> render(:show, comment: comment)
    end
  end

  def update(conn, %{"club_post_id" => club_post_id, "id" => id, "comment" => comment_params}) do
    with {:ok, comment} <-
           Clubs.update_club_comment(%UpdateClubCommentUsecaseDto{
             user: current_user(conn),
             club_post_id: club_post_id,
             comment_id: id,
             attrs: comment_params
           }) do
      render(conn, :show, comment: comment)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
