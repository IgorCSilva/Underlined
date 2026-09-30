defmodule Api.Accounts do
  @moduledoc """
  The Accounts context: registration, authentication, sessions, email
  confirmation/password reset, and profile management (Step 1).
  """

  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.{User, UserToken, RefreshToken}

  defp mailer, do: Application.get_env(:api, :mailer, Api.Infra.SwooshMailer)
  defp object_store, do: Application.get_env(:api, :object_store, Api.Infra.S3ObjectStore)

  ## Users

  def get_user(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(User, uuid)
      :error -> nil
    end
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def update_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def update_avatar(%User{} = user, binary, content_type) do
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

  ## Email confirmation

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      mailer().deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> {:error, :invalid_token}
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Password reset

  def deliver_user_reset_password_instructions(%User{} = user, reset_url_fun)
      when is_function(reset_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    mailer().deliver_reset_password_instructions(user, reset_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(%User{} = user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Ecto.Multi.delete_all(:refresh_tokens, RefreshToken.by_user_query(user))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Sessions (Guardian access token + opaque refresh token)

  @doc """
  Issues an access token (JWT, via Guardian) and a refresh token for the given
  user. `remember_me?` controls how long the refresh token stays valid.
  """
  def create_session(%User{} = user, remember_me? \\ false) do
    {:ok, access_token, _claims} = Api.Accounts.Guardian.encode_and_sign(user)
    {refresh_token, refresh_token_struct} = RefreshToken.build(user, remember_me?)
    Repo.insert!(refresh_token_struct)
    {:ok, access_token, refresh_token}
  end

  @doc """
  Rotates a refresh token: verifies it, deletes it, and issues a new
  access/refresh token pair for its owner. Returns `:error` if the refresh
  token is missing/expired.

  The returned `remember_me?` is the flag the *original* token was issued
  with — callers must carry it into the new cookie's lifetime, or "remember
  me" silently degrades to a session cookie after the first rotation.
  """
  def refresh_session(refresh_token) when is_binary(refresh_token) do
    case Repo.one(RefreshToken.valid_query(refresh_token)) do
      {stored, user} ->
        Repo.delete!(stored)
        {:ok, access_token, new_refresh_token} = create_session(user, stored.remember_me)
        {:ok, access_token, new_refresh_token, stored.remember_me}

      nil ->
        :error
    end
  end

  def revoke_refresh_token(refresh_token) when is_binary(refresh_token) do
    Repo.delete_all(RefreshToken.by_hash_query(refresh_token))
    :ok
  end

  def revoke_all_refresh_tokens(%User{} = user) do
    Repo.delete_all(RefreshToken.by_user_query(user))
    :ok
  end
end
