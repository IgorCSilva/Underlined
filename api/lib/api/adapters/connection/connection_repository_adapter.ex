defmodule Api.Adapters.Connection.ConnectionRepositoryAdapter do
  @moduledoc """
  Adapts a connection repository (the adaptee) to the domain: calls it for
  the database entity/entities, then converts the result(s) into the pure
  Api.Domain.Connection business entity.

  Each DB connection row stores a fixed `post_id`/`related_post_id`
  direction, but a connection is meant to show up identically on both
  posts it links — so this adapter resolves `connected_post` relative to
  whichever `post_id` the caller asked about, not the row's storage order.
  """

  alias Api.Adapters.Post.PostRepositoryAdapter
  alias Api.Domain.Connection, as: DomainConnection

  def connect_posts(user, post_id, related_post_id, relationship_type, adaptee) do
    case adaptee.connect_posts(user, post_id, related_post_id, relationship_type) do
      {:error, :not_found} -> {:error, :not_found}
      {:error, :cannot_connect_self} -> {:error, :cannot_connect_self}
      {:error, changeset} -> {:error, changeset}
      {:ok, db_connection} -> {:ok, to_domain(db_connection, post_id)}
    end
  end

  def list_connections(post_id, adaptee) do
    case adaptee.list_connections(post_id) do
      {:error, :not_found} -> {:error, :not_found}
      {:ok, db_connections} -> {:ok, Enum.map(db_connections, &to_domain(&1, post_id))}
    end
  end

  defp to_domain(db_connection, post_id) do
    connected_post =
      if db_connection.post_id == post_id, do: db_connection.related_post, else: db_connection.post

    %DomainConnection{
      id: db_connection.id,
      relationship_type: db_connection.relationship_type,
      connected_post: PostRepositoryAdapter.to_domain(connected_post),
      inserted_at: db_connection.inserted_at
    }
  end
end
