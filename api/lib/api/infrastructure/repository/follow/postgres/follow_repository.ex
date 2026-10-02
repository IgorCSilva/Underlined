defmodule Api.Infrastructure.Repository.Follow.Postgres.FollowRepository do
  @moduledoc """
  Postgres-backed data access for the follow entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Follow.Postgres.Follow
  alias Api.Infrastructure.Repository.User.Postgres.UserRepository
  alias Api.Repo

  @doc "Whether `follower` follows the user identified by `followee_id`."
  def following?(follower, followee_id) do
    Repo.exists?(
      from f in Follow, where: f.follower_id == ^follower.id and f.followee_id == ^followee_id
    )
  end

  @doc """
  Follows the user `followee_id` on behalf of `follower`. Idempotent:
  following an already-followed user just returns the current state
  instead of inserting a duplicate row.
  """
  def follow_user(follower, followee_id) do
    cond do
      follower.id == followee_id ->
        {:error, :cannot_follow_self}

      is_nil(UserRepository.get_user(followee_id)) ->
        {:error, :not_found}

      Repo.get_by(Follow, follower_id: follower.id, followee_id: followee_id) ->
        {:ok, %{following: true}}

      true ->
        attrs = %{"follower_id" => follower.id, "followee_id" => followee_id}

        case %Follow{} |> Follow.changeset(attrs) |> Repo.insert() do
          {:ok, _follow} -> {:ok, %{following: true}}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  Unfollows the user `followee_id` on behalf of `follower`. Idempotent:
  unfollowing a user the caller doesn't follow is a no-op that returns the
  current state.
  """
  def unfollow_user(follower, followee_id) do
    case Repo.get_by(Follow, follower_id: follower.id, followee_id: followee_id) do
      nil ->
        {:ok, %{following: false}}

      follow ->
        Repo.delete!(follow)
        {:ok, %{following: false}}
    end
  end
end
