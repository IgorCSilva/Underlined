defmodule Api.Infrastructure.Repository.Connection.Postgres.ConnectionRepository do
  @moduledoc """
  Postgres-backed data access for the post-connection entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Connection.Postgres.Connection
  alias Api.Infrastructure.Repository.Post.Postgres.PostRepository
  alias Api.Repo

  @post_preloads [:book, :passage, :keywords, :user]

  @doc """
  Links `post_id` to `related_post_id` with `relationship_type`, on behalf
  of `user`. Returns `{:error, :not_found}` if either post doesn't exist,
  `{:error, :cannot_connect_self}` if they're the same post. Idempotent:
  connecting the same pair with the same relationship type again just
  returns the existing connection instead of inserting a duplicate row.
  """
  def connect_posts(user, post_id, related_post_id, relationship_type) do
    cond do
      post_id == related_post_id ->
        {:error, :cannot_connect_self}

      is_nil(PostRepository.fetch_post(post_id)) ->
        {:error, :not_found}

      is_nil(PostRepository.fetch_post(related_post_id)) ->
        {:error, :not_found}

      existing =
          Repo.get_by(Connection,
            post_id: post_id,
            related_post_id: related_post_id,
            relationship_type: relationship_type
          ) ->
        {:ok, Repo.preload(existing, post: @post_preloads, related_post: @post_preloads)}

      true ->
        attrs = %{
          "user_id" => user.id,
          "post_id" => post_id,
          "related_post_id" => related_post_id,
          "relationship_type" => relationship_type
        }

        case %Connection{} |> Connection.changeset(attrs) |> Repo.insert() do
          {:ok, connection} ->
            {:ok, Repo.preload(connection, post: @post_preloads, related_post: @post_preloads)}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Every connection involving `post_id`, on either side, newest first.
  Returns `{:error, :not_found}` when `post_id` doesn't exist.
  """
  def list_connections(post_id) do
    case PostRepository.fetch_post(post_id) do
      nil ->
        {:error, :not_found}

      _post ->
        connections =
          Connection
          |> where([c], c.post_id == ^post_id or c.related_post_id == ^post_id)
          |> order_by(desc: :inserted_at)
          |> Repo.all()
          |> Repo.preload(post: @post_preloads, related_post: @post_preloads)

        {:ok, connections}
    end
  end

  @doc """
  Fetches a single connection by its own id, with both posts preloaded.
  Returns `nil` if `id` isn't a valid UUID or no connection exists with it.
  """
  def get_connection(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        Connection
        |> Repo.get(uuid)
        |> Repo.preload(post: @post_preloads, related_post: @post_preloads)

      :error ->
        nil
    end
  end
end
