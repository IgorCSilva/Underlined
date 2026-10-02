defmodule Api.Infrastructure.Repository.RefreshToken.Postgres.RefreshTokenRepository do
  @moduledoc """
  Postgres-backed data access for the refresh-token entity.
  """

  alias Api.Infrastructure.Repository.RefreshToken.Postgres.RefreshToken
  alias Api.Repo

  @doc """
  Builds and persists a new refresh token for `user`. Returns the plaintext
  token to hand to the client, alongside the persisted token entity.
  """
  def insert(user, remember_me?) do
    {token, refresh_token} = RefreshToken.build(user, remember_me?)
    Repo.insert!(refresh_token)
    token
  end

  @doc """
  Returns `{stored_token, user}` for a valid, unexpired refresh token, or
  `nil` if it doesn't exist or has expired.
  """
  def find_valid(token) do
    Repo.one(RefreshToken.valid_query(token))
  end

  def delete(%RefreshToken{} = refresh_token), do: Repo.delete!(refresh_token)

  def delete_by_hash(token), do: Repo.delete_all(RefreshToken.by_hash_query(token))

  def delete_all_for_user(user), do: Repo.delete_all(RefreshToken.by_user_query(user))
end
