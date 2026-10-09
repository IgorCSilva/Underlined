defmodule ApiWeb.ConnectionController do
  use ApiWeb, :controller

  alias Api.Adapters.Posts
  alias Api.Usecases.Connection.ConnectPosts.ConnectPostsUsecaseDto
  alias Api.Usecases.Connection.ListConnections.ListConnectionsUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"id" => post_id}) do
    with {:ok, connections} <-
           Posts.list_connections(%ListConnectionsUsecaseDto{id: post_id}) do
      render(conn, :index, connections: connections)
    end
  end

  def create(conn, %{"post_id" => post_id, "connection" => connection_params}) do
    with {:ok, connection} <-
           Posts.connect_posts(%ConnectPostsUsecaseDto{
             user: current_user(conn),
             post_id: post_id,
             related_post_id: connection_params["related_post_id"],
             relationship_type: connection_params["relationship_type"]
           }) do
      conn
      |> put_status(:created)
      |> render(:show, connection: connection)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
