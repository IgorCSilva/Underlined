defmodule ApiWeb.ConnectionCommentController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.ConnectionComment.CreateConnectionComment.CreateConnectionCommentUsecaseDto
  alias Api.Usecases.ConnectionComment.ListConnectionComments.ListConnectionCommentsUsecaseDto
  alias Api.Usecases.ConnectionComment.UpdateConnectionComment.UpdateConnectionCommentUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"connection_id" => connection_id}) do
    comments =
      Posts.list_connection_comments(%ListConnectionCommentsUsecaseDto{connection_id: connection_id})

    render(conn, :index, comments: comments)
  end

  def create(conn, %{"connection_id" => connection_id, "comment" => comment_params}) do
    with {:ok, comment} <-
           Posts.create_connection_comment(%CreateConnectionCommentUsecaseDto{
             user: current_user(conn),
             connection_id: connection_id,
             attrs: comment_params
           }) do
      conn
      |> put_status(:created)
      |> render(:show, comment: comment)
    end
  end

  def update(conn, %{"connection_id" => connection_id, "id" => id, "comment" => comment_params}) do
    with {:ok, comment} <-
           Posts.update_connection_comment(%UpdateConnectionCommentUsecaseDto{
             user: current_user(conn),
             connection_id: connection_id,
             comment_id: id,
             attrs: comment_params
           }) do
      render(conn, :show, comment: comment)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
