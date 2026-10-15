defmodule ApiWeb.ConnectionCommentJSON do
  @moduledoc """
  A connection-comment is, domain-wise, almost the same `Api.Domain.Comment`
  entity a post-comment is — except it also carries a `side` (which debate
  post it agrees with). That one extra field is why this can't delegate to
  `ApiWeb.CommentJSON` the way it used to: post-comment responses must never
  expose `side`.
  """

  alias Api.Domain.Comment

  def index(%{comments: comments}), do: %{data: Enum.map(comments, &data/1)}
  def show(%{comment: comment}), do: %{data: data(comment)}

  def data(%Comment{} = comment) do
    %{
      id: comment.id,
      type: comment.type,
      body: comment.body,
      side: comment.side,
      inserted_at: comment.inserted_at,
      updated_at: comment.updated_at,
      parent_comment_id: comment.parent_comment_id,
      user: %{
        id: comment.user.id,
        name: comment.user.name,
        avatar_url: comment.user.avatar_url
      },
      replies: replies_data(comment)
    }
  end

  defp replies_data(%{replies: replies}) when is_list(replies), do: Enum.map(replies, &data/1)
  defp replies_data(_), do: []
end
