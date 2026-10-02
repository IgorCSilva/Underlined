defmodule Api.Infrastructure.Repository.Like.Postgres.LikeRepository do
  @moduledoc """
  Postgres-backed data access for the like entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Like.Postgres.Like
  alias Api.Infrastructure.Repository.Post.Postgres.{Post, PostRepository}
  alias Api.Repo

  @doc "Returns the set of post ids, among `post_ids`, that `user` has liked."
  def liked_post_ids(user, post_ids) do
    Like
    |> where([l], l.user_id == ^user.id and l.post_id in ^post_ids)
    |> select([l], l.post_id)
    |> Repo.all()
    |> MapSet.new()
  end

  def liked?(user, post_id) do
    Repo.exists?(from l in Like, where: l.user_id == ^user.id and l.post_id == ^post_id)
  end

  @doc """
  Likes the post `post_id` on behalf of `user`. Idempotent: liking an
  already-liked post just returns the current state instead of inserting a
  duplicate row.
  """
  def like_post(user, post_id) do
    case PostRepository.fetch_post(post_id) do
      nil -> {:error, :not_found}
      post -> do_like(user, post)
    end
  end

  @doc """
  Unlikes the post `post_id` on behalf of `user`. Idempotent: unliking a
  post the user hasn't liked is a no-op that returns the current state.
  """
  def unlike_post(user, post_id) do
    case PostRepository.fetch_post(post_id) do
      nil -> {:error, :not_found}
      post -> do_unlike(user, post)
    end
  end

  defp do_like(user, post) do
    if Repo.get_by(Like, user_id: user.id, post_id: post.id) do
      {:ok, %{liked: true, like_count: post.like_count}}
    else
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :like,
          Like.changeset(%Like{}, %{"user_id" => user.id, "post_id" => post.id})
        )
        |> Ecto.Multi.update_all(:post, fn _ -> where(Post, id: ^post.id) end,
          inc: [like_count: 1]
        )

      case Repo.transaction(multi) do
        {:ok, _changes} -> {:ok, %{liked: true, like_count: post.like_count + 1}}
        {:error, :like, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  defp do_unlike(user, post) do
    case Repo.get_by(Like, user_id: user.id, post_id: post.id) do
      nil ->
        {:ok, %{liked: false, like_count: post.like_count}}

      like ->
        multi =
          Ecto.Multi.new()
          |> Ecto.Multi.delete(:like, like)
          |> Ecto.Multi.update_all(:post, fn _ -> where(Post, id: ^post.id) end,
            inc: [like_count: -1]
          )

        {:ok, _changes} = Repo.transaction(multi)
        {:ok, %{liked: false, like_count: max(post.like_count - 1, 0)}}
    end
  end
end
