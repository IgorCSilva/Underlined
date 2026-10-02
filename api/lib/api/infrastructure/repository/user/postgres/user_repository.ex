defmodule Api.Infrastructure.Repository.User.Postgres.UserRepository do
  @moduledoc """
  Postgres-backed data access for the user entity.
  """

  alias Api.Infrastructure.Repository.RefreshToken.Postgres.RefreshToken
  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Infrastructure.Repository.UserToken.Postgres.UserToken
  alias Api.Repo

  def get_user(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(User, uuid)
      :error -> nil
    end
  end

  @doc """
  Sets a new password and revokes every existing email token and refresh
  token the user had, atomically, so old sessions and confirmation links
  stop working.
  """
  def reset_password(%User{} = user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Ecto.Multi.delete_all(:refresh_tokens, RefreshToken.by_user_query(user))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes} -> {:error, changeset}
    end
  end
end
