defmodule ApiWeb.PostController do
  use ApiWeb, :controller

  alias Api.Posts

  action_fallback ApiWeb.FallbackController

  def show(conn, %{"id" => id}) do
    case Posts.get_post(id) do
      nil -> {:error, :not_found}
      post -> render(conn, :show, post: post)
    end
  end

  def create(conn, %{"post" => post_params}) do
    with {:ok, post} <- Posts.create_post(current_user(conn), post_params) do
      conn
      |> put_status(:created)
      |> render(:show, post: post)
    end
  end

  defp current_user(conn), do: Api.Accounts.Guardian.Plug.current_resource(conn)
end
