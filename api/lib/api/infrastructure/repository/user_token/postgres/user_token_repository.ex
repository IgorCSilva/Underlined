defmodule Api.Infrastructure.Repository.UserToken.Postgres.UserTokenRepository do
  @moduledoc """
  Postgres-backed data access for the user-token entity.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Infrastructure.Repository.UserToken.Postgres.UserToken
  alias Api.Repo

  @doc """
  Builds and persists a one-time email token for `context` (e.g.
  "confirm"/"reset_password"). Returns the plaintext token to embed in the
  email link, alongside the persisted token entity.
  """
  def create_email_token(user, context) do
    {encoded_token, user_token} = UserToken.build_email_token(user, context)
    Repo.insert!(user_token)
    encoded_token
  end

  @doc """
  Verifies a one-time email token for `context`, returning the owning user
  if it's still valid and unexpired, or `nil` otherwise.
  """
  def verify_email_token(token, context) do
    case UserToken.verify_email_token_query(token, context) do
      {:ok, query} -> Repo.one(query)
      :error -> nil
    end
  end

  @doc """
  Marks `user` as confirmed and deletes their outstanding "confirm" tokens,
  atomically.
  """
  def confirm_user(%User{} = user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes} -> {:error, changeset}
    end
  end
end
