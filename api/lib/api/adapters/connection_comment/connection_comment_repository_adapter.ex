defmodule Api.Adapters.ConnectionComment.ConnectionCommentRepositoryAdapter do
  @moduledoc """
  Adapts a connection-comment repository (the adaptee) to the domain: calls
  it for the database entity/entities, then converts the result(s) into the
  pure Api.Domain.Comment business entity.

  A fork of `Api.Adapters.Comment.CommentRepositoryAdapter` rather than a
  shared module: connection comments carry a `side` (which debate post they
  agree with), while post comments never do. Keeping this as its own
  adapter means the post-comment path never needs to know about `side`.
  """

  alias Api.Adapters.User.UserRepositoryAdapter
  alias Api.Domain.Comment, as: DomainComment

  def create_comment(user, connection_id, attrs, adaptee) do
    case adaptee.create_comment(user, connection_id, attrs) do
      {:ok, db_comment} -> {:ok, to_domain(db_comment)}
      {:error, reason} -> {:error, reason}
    end
  end

  def list_comments(connection_id, adaptee) do
    adaptee.list_comments(connection_id) |> Enum.map(&to_domain/1)
  end

  def update_comment(user, connection_id, comment_id, attrs, adaptee) do
    case adaptee.update_comment(user, connection_id, comment_id, attrs) do
      {:ok, db_comment} -> {:ok, to_domain(db_comment)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Converts a Postgres connection-comment entity (with :user/:replies preloaded) into the pure domain entity."
  def to_domain(db_comment) do
    %DomainComment{
      id: db_comment.id,
      type: db_comment.type,
      body: db_comment.body,
      side: db_comment.side,
      parent_comment_id: db_comment.parent_comment_id,
      user: UserRepositoryAdapter.to_domain(db_comment.user),
      replies: replies_to_domain(db_comment),
      inserted_at: db_comment.inserted_at,
      updated_at: db_comment.updated_at
    }
  end

  defp replies_to_domain(%{replies: replies}) when is_list(replies),
    do: Enum.map(replies, &to_domain/1)

  defp replies_to_domain(_db_comment), do: []
end
