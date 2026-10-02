defmodule Api.Usecases.User.UpdateAvatar.UpdateAvatarUsecase do
  @moduledoc """
  Stores a new avatar in the object store and saves its URL on the user,
  then best-effort deletes the previous avatar.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Repo
  alias Api.Usecases.User.UpdateAvatar.UpdateAvatarUsecaseDto

  def call(%UpdateAvatarUsecaseDto{
        user: %User{} = user,
        binary: binary,
        content_type: content_type
      }) do
    old_avatar_url = user.avatar_url

    with {:ok, url} <- object_store().put_avatar(user.id, binary, content_type),
         {:ok, updated_user} <- user |> User.avatar_changeset(url) |> Repo.update() do
      delete_old_avatar(old_avatar_url)
      {:ok, updated_user}
    end
  end

  # Best-effort cleanup: the new avatar is already saved, so a failure to
  # delete the old object is logged, not surfaced as a request error.
  defp delete_old_avatar(nil), do: :ok

  defp delete_old_avatar(url) do
    case object_store().delete_avatar(url) do
      :ok ->
        :ok

      {:error, reason} ->
        require Logger
        Logger.warning("Failed to delete old avatar #{url}: #{inspect(reason)}")
        :ok
    end
  end

  defp object_store,
    do: Application.get_env(:api, :object_store, Api.Infrastructure.S3ObjectStore)
end
