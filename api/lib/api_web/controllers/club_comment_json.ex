defmodule ApiWeb.ClubCommentJSON do
  @moduledoc """
  A club-post comment is, domain-wise, exactly the same `Api.Domain.Comment`
  entity a regular post's comment is (unlike a connection's debate
  comment, it carries no `side`), so rendering just delegates to
  `ApiWeb.CommentJSON` instead of duplicating its shape.
  """

  alias ApiWeb.CommentJSON

  def index(%{comments: comments}), do: %{data: Enum.map(comments, &CommentJSON.data/1)}
  def show(%{comment: comment}), do: %{data: CommentJSON.data(comment)}
end
