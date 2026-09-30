defmodule ApiWeb.ProfileController do
  use ApiWeb, :controller

  alias Api.Accounts

  action_fallback ApiWeb.FallbackController

  @allowed_content_types ~w(image/png image/jpeg image/webp)

  def show(conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :not_found}
      user -> render(conn, :show, user: user)
    end
  end

  def me(conn, _params) do
    render(conn, :show, user: current_user(conn))
  end

  def update(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.update_profile(current_user(conn), user_params) do
      render(conn, :show, user: user)
    end
  end

  def update_avatar(conn, %{"avatar" => %Plug.Upload{} = upload}) do
    with :ok <- validate_content_type(upload.content_type),
         binary <- File.read!(upload.path),
         {:ok, user} <- Accounts.update_avatar(current_user(conn), binary, upload.content_type) do
      render(conn, :show, user: user)
    end
  end

  def update_avatar(_conn, _params), do: {:error, :invalid_upload}

  defp validate_content_type(content_type) when content_type in @allowed_content_types, do: :ok
  defp validate_content_type(_), do: {:error, :invalid_upload}

  defp current_user(conn), do: Api.Accounts.Guardian.Plug.current_resource(conn)
end
