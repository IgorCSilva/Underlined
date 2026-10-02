defmodule ApiWeb.ProfileController do
  use ApiWeb, :controller

  alias Api.Adapters.Accounts
  alias Api.Usecases.User.GetUser.GetUserUsecaseDto
  alias Api.Usecases.User.UpdateAvatar.UpdateAvatarUsecaseDto
  alias Api.Usecases.User.UpdateProfile.UpdateProfileUsecaseDto

  action_fallback ApiWeb.FallbackController

  @allowed_content_types ~w(image/png image/jpeg image/webp)

  def show(conn, %{"id" => id}) do
    case Accounts.get_user(%GetUserUsecaseDto{id: id, current_user: current_user(conn)}) do
      nil -> {:error, :not_found}
      user -> render(conn, :show, user: user)
    end
  end

  def me(conn, _params) do
    render(conn, :show, user: current_user(conn))
  end

  def update(conn, %{"user" => user_params}) do
    dto = %UpdateProfileUsecaseDto{user: current_user(conn), attrs: user_params}

    with {:ok, user} <- Accounts.update_profile(dto) do
      render(conn, :show, user: user)
    end
  end

  def update_avatar(conn, %{"avatar" => %Plug.Upload{} = upload}) do
    with :ok <- validate_content_type(upload.content_type),
         binary <- File.read!(upload.path),
         dto = %UpdateAvatarUsecaseDto{
           user: current_user(conn),
           binary: binary,
           content_type: upload.content_type
         },
         {:ok, user} <- Accounts.update_avatar(dto) do
      render(conn, :show, user: user)
    end
  end

  def update_avatar(_conn, _params), do: {:error, :invalid_upload}

  defp validate_content_type(content_type) when content_type in @allowed_content_types, do: :ok
  defp validate_content_type(_), do: {:error, :invalid_upload}

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
