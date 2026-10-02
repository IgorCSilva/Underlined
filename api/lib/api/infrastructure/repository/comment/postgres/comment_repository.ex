defmodule Api.Infrastructure.Repository.Comment.Postgres.CommentRepository do
  @moduledoc """
  Postgres-backed data access for the comment entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Comment.Postgres.Comment
  alias Api.Infrastructure.Repository.Post.Postgres.{Post, PostRepository}
  alias Api.Infrastructure.CommentRateLimiter
  alias Api.Repo

  @comment_rate_limit 5
  @comment_rate_scale_ms :timer.seconds(60)

  @doc """
  Creates a top-level comment (no `parent_comment_id`) or a reply (one
  level deep only — the parent must itself be a top-level comment).
  """
  def create_comment(user, post_id, attrs) do
    case PostRepository.fetch_post(post_id) do
      nil -> {:error, :not_found}
      post -> do_create_comment(user, post, attrs)
    end
  end

  defp do_create_comment(user, post, attrs) do
    with :ok <- check_comment_rate_limit(user),
         {:ok, type, parent_comment_id} <- resolve_parent(post, attrs["parent_comment_id"]) do
      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :comment,
          Comment.changeset(%Comment{}, %{
            "user_id" => user.id,
            "post_id" => post.id,
            "parent_comment_id" => parent_comment_id,
            "type" => type,
            "body" => attrs["body"]
          })
        )
        |> Ecto.Multi.update_all(:post, fn _ -> where(Post, id: ^post.id) end,
          inc: [comment_count: 1]
        )

      case Repo.transaction(multi) do
        {:ok, %{comment: comment}} -> {:ok, Repo.preload(comment, [:user, :replies])}
        {:error, :comment, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  @doc """
  Top-level comments for a post, oldest first, each preloaded with its
  (also oldest-first) replies.
  """
  def list_comments(post_id) do
    case Ecto.UUID.cast(post_id) do
      {:ok, uuid} ->
        replies_query = from(c in Comment, order_by: [asc: c.inserted_at])

        Comment
        |> where([c], c.post_id == ^uuid and is_nil(c.parent_comment_id))
        |> order_by(asc: :inserted_at)
        |> Repo.all()
        |> Repo.preload(user: [], replies: {replies_query, [:user]})

      :error ->
        []
    end
  end

  defp check_comment_rate_limit(user) do
    case CommentRateLimiter.hit("comment:#{user.id}", @comment_rate_scale_ms, @comment_rate_limit) do
      {:allow, _count} -> :ok
      {:deny, _retry_after} -> {:error, :rate_limited}
    end
  end

  defp resolve_parent(_post, nil), do: {:ok, "comment", nil}

  defp resolve_parent(post, parent_comment_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(parent_comment_id),
         %Comment{type: "comment"} = parent <- Repo.get_by(Comment, id: uuid, post_id: post.id) do
      {:ok, "reply", parent.id}
    else
      _ -> {:error, :invalid_parent}
    end
  end
end
