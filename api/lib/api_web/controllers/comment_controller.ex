defmodule ApiWeb.CommentController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.Comment.CreateComment.CreateCommentUsecaseDto
  alias Api.Usecases.Comment.ListComments.ListCommentsUsecaseDto
  alias Api.Usecases.Comment.UpdateComment.UpdateCommentUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"post_id" => post_id}) do
    comments = Posts.list_comments(%ListCommentsUsecaseDto{post_id: post_id})
    render(conn, :index, comments: comments)
  end

  def create(conn, %{"post_id" => post_id, "comment" => comment_params}) do
    with {:ok, comment} <-
           Posts.create_comment(%CreateCommentUsecaseDto{
             user: current_user(conn),
             post_id: post_id,
             attrs: comment_params
           }) do
      conn
      |> put_status(:created)
      |> render(:show, comment: comment)
    end
  end

  def update(conn, %{"post_id" => post_id, "id" => id, "comment" => comment_params}) do
    with {:ok, comment} <-
           Posts.update_comment(%UpdateCommentUsecaseDto{
             user: current_user(conn),
             post_id: post_id,
             comment_id: id,
             attrs: comment_params
           }) do
      render(conn, :show, comment: comment)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
