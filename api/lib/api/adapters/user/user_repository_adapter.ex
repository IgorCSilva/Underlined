defmodule Api.Adapters.User.UserRepositoryAdapter do
  @moduledoc """
  Adapts a user repository (the adaptee) to the domain: calls it for the
  database entity, then converts the result into the pure Api.Domain.User
  business entity.
  """

  alias Api.Domain.User, as: DomainUser
  alias Api.Infrastructure.Repository.Follow.Postgres.FollowRepository

  def get_user(id, current_user, adaptee) do
    case adaptee.get_user(id) do
      nil -> nil
      db_user -> db_user |> annotate_followed(current_user) |> to_domain()
    end
  end

  defp annotate_followed(db_user, nil), do: db_user

  defp annotate_followed(db_user, current_user) do
    %{db_user | followed_by_user: FollowRepository.following?(current_user, db_user.id)}
  end

  @doc """
  Resets `user`'s password and revokes their tokens/sessions. Returns the
  Postgres-backed user (not converted to the domain entity): callers along
  this flow (password reset) still operate on the Postgres entity, same as
  before this migration.
  """
  def reset_password(user, attrs, adaptee), do: adaptee.reset_password(user, attrs)

  @doc "Converts a Postgres user entity into the pure domain entity."
  def to_domain(db_user) do
    %DomainUser{
      id: db_user.id,
      email: db_user.email,
      hashed_password: db_user.hashed_password,
      name: db_user.name,
      bio: db_user.bio,
      avatar_url: db_user.avatar_url,
      confirmed_at: db_user.confirmed_at,
      enabled: db_user.enabled,
      followed_by_user: db_user.followed_by_user,
      inserted_at: db_user.inserted_at,
      updated_at: db_user.updated_at
    }
  end
end
