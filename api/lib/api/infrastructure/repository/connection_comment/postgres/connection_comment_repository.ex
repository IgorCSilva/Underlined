defmodule Api.Infrastructure.Repository.ConnectionComment.Postgres.ConnectionCommentRepository do
  @moduledoc """
  Postgres-backed data access for a connection's debate-thread comments.
  Mirrors `Api.Infrastructure.Repository.Comment.Postgres.CommentRepository`
  (same reply-nesting/rate-limit rules), scoped to a connection instead of
  a post — there's no `comment_count` to bump here, since connections
  don't carry one.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Connection.Postgres.ConnectionRepository
  alias Api.Infrastructure.Repository.ConnectionComment.Postgres.ConnectionComment
  alias Api.Infrastructure.CommentRateLimiter
  alias Api.Repo

  @comment_rate_limit 5
  @comment_rate_scale_ms :timer.seconds(60)

  @doc """
  Creates a top-level comment (no `parent_comment_id`) or a reply (one
  level deep only — the parent must itself be a top-level comment) on
  `connection_id`'s debate thread.
  """
  def create_comment(user, connection_id, attrs) do
    case ConnectionRepository.get_connection(connection_id) do
      nil -> {:error, :not_found}
      connection -> do_create_comment(user, connection, attrs)
    end
  end

  defp do_create_comment(user, connection, attrs) do
    with :ok <- check_comment_rate_limit(user),
         {:ok, type, parent_comment_id} <- resolve_parent(connection, attrs["parent_comment_id"]) do
      %ConnectionComment{}
      |> ConnectionComment.changeset(
        %{
          "user_id" => user.id,
          "connection_id" => connection.id,
          "parent_comment_id" => parent_comment_id,
          "type" => type,
          "body" => attrs["body"]
        }
        |> maybe_put_side(attrs["side"])
      )
      |> Repo.insert()
      |> case do
        {:ok, comment} -> {:ok, Repo.preload(comment, [:user, :replies])}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc """
  Edits a comment's body. Only the comment's author may edit it.
  """
  def update_comment(user, connection_id, comment_id, attrs) do
    with {:ok, comment} <- fetch_own_comment(user, connection_id, comment_id) do
      comment
      |> ConnectionComment.update_changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          {:ok, Repo.preload(updated, [:user, replies: {replies_query(), [:user]}])}

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  defp fetch_own_comment(user, connection_id, comment_id) do
    case Ecto.UUID.cast(comment_id) do
      {:ok, uuid} ->
        case Repo.get_by(ConnectionComment, id: uuid, connection_id: connection_id) do
          nil -> {:error, :not_found}
          %ConnectionComment{user_id: user_id} when user_id != user.id -> {:error, :forbidden}
          comment -> {:ok, comment}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Top-level comments for a connection's debate thread, oldest first, each
  preloaded with its (also oldest-first) replies.
  """
  def list_comments(connection_id) do
    case Ecto.UUID.cast(connection_id) do
      {:ok, uuid} ->
        ConnectionComment
        |> where([c], c.connection_id == ^uuid and is_nil(c.parent_comment_id))
        |> order_by(asc: :inserted_at)
        |> Repo.all()
        |> Repo.preload(user: [], replies: {replies_query(), [:user]})

      :error ->
        []
    end
  end

  defp replies_query, do: from(c in ConnectionComment, order_by: [asc: c.inserted_at])

  # Shares the same per-user bucket as post comments (`comment:<user_id>`):
  # this is one global "don't spam comments" limit, regardless of whether
  # the thread is scoped to a post or to a connection's debate.
  defp check_comment_rate_limit(user) do
    case CommentRateLimiter.hit("comment:#{user.id}", @comment_rate_scale_ms, @comment_rate_limit) do
      {:allow, _count} -> :ok
      {:deny, _retry_after} -> {:error, :rate_limited}
    end
  end

  defp maybe_put_side(map, nil), do: map
  defp maybe_put_side(map, side), do: Map.put(map, "side", side)

  defp resolve_parent(_connection, nil), do: {:ok, "comment", nil}

  defp resolve_parent(connection, parent_comment_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(parent_comment_id),
         %ConnectionComment{type: "comment"} = parent <-
           Repo.get_by(ConnectionComment, id: uuid, connection_id: connection.id) do
      {:ok, "reply", parent.id}
    else
      _ -> {:error, :invalid_parent}
    end
  end
end
