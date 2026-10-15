defmodule Api.Infrastructure.Repository.Club.Postgres.ClubCommentRepository do
  @moduledoc """
  Postgres-backed data access for comments on a club's discussion posts.
  Mirrors `Api.Infrastructure.Repository.Comment.Postgres.CommentRepository`
  (same reply-nesting/rate-limit rules, same `comment_count` bump),
  scoped to a club post instead of a regular post, and additionally
  restricted to the club's own members — same membership rule
  `ClubPostRepository` enforces for creating the post itself.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Club.Postgres.{ClubComment, ClubMembership, ClubPost}
  alias Api.Infrastructure.CommentRateLimiter
  alias Api.Repo

  @comment_rate_limit 5
  @comment_rate_scale_ms :timer.seconds(60)

  @doc """
  Creates a top-level comment (no `parent_comment_id`) or a reply (one
  level deep only — the parent must itself be a top-level comment) on
  `club_post_id`. Only a member of the post's club may comment.
  """
  def create_comment(user, club_post_id, attrs) do
    case Repo.get(ClubPost, club_post_id) do
      nil -> {:error, :not_found}
      post -> do_create_comment(user, post, attrs)
    end
  end

  defp do_create_comment(user, post, attrs) do
    with :ok <- authorize_member(post.club_id, user),
         :ok <- check_comment_rate_limit(user),
         {:ok, type, parent_comment_id} <- resolve_parent(post, attrs["parent_comment_id"]) do
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :comment,
          ClubComment.changeset(%ClubComment{}, %{
            "user_id" => user.id,
            "club_post_id" => post.id,
            "parent_comment_id" => parent_comment_id,
            "type" => type,
            "body" => attrs["body"]
          })
        )
        |> Ecto.Multi.update_all(:club_post, fn _ -> where(ClubPost, id: ^post.id) end,
          inc: [comment_count: 1]
        )

      case Repo.transaction(multi) do
        {:ok, %{comment: comment}} -> {:ok, Repo.preload(comment, [:user, :replies])}
        {:error, :comment, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  @doc """
  Edits a comment's body. Only the comment's author may edit it.
  """
  def update_comment(user, club_post_id, comment_id, attrs) do
    with {:ok, comment} <- fetch_own_comment(user, club_post_id, comment_id) do
      comment
      |> ClubComment.update_changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          {:ok, Repo.preload(updated, [:user, replies: {replies_query(), [:user]}])}

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  defp fetch_own_comment(user, club_post_id, comment_id) do
    case Ecto.UUID.cast(comment_id) do
      {:ok, uuid} ->
        case Repo.get_by(ClubComment, id: uuid, club_post_id: club_post_id) do
          nil -> {:error, :not_found}
          %ClubComment{user_id: user_id} when user_id != user.id -> {:error, :forbidden}
          comment -> {:ok, comment}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Top-level comments for a club post, oldest first, each preloaded with
  its (also oldest-first) replies.
  """
  def list_comments(club_post_id) do
    case Ecto.UUID.cast(club_post_id) do
      {:ok, uuid} ->
        ClubComment
        |> where([c], c.club_post_id == ^uuid and is_nil(c.parent_comment_id))
        |> order_by(asc: :inserted_at)
        |> Repo.all()
        |> Repo.preload(user: [], replies: {replies_query(), [:user]})

      :error ->
        []
    end
  end

  defp replies_query, do: from(c in ClubComment, order_by: [asc: c.inserted_at])

  defp authorize_member(club_id, user) do
    if Repo.exists?(
         from m in ClubMembership, where: m.club_id == ^club_id and m.user_id == ^user.id
       ) do
      :ok
    else
      {:error, :forbidden}
    end
  end

  # Shares the same per-user bucket as post comments (`comment:<user_id>`):
  # one global "don't spam comments" limit, regardless of whether the
  # thread is scoped to a post, a connection's debate, or a club post.
  defp check_comment_rate_limit(user) do
    case CommentRateLimiter.hit("comment:#{user.id}", @comment_rate_scale_ms, @comment_rate_limit) do
      {:allow, _count} -> :ok
      {:deny, _retry_after} -> {:error, :rate_limited}
    end
  end

  defp resolve_parent(_post, nil), do: {:ok, "comment", nil}

  defp resolve_parent(post, parent_comment_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(parent_comment_id),
         %ClubComment{type: "comment"} = parent <-
           Repo.get_by(ClubComment, id: uuid, club_post_id: post.id) do
      {:ok, "reply", parent.id}
    else
      _ -> {:error, :invalid_parent}
    end
  end
end
