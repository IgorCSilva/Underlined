defmodule ApiWeb.ConnectionCommentJSON do
  @moduledoc """
  A connection-comment is, domain-wise, the same `Api.Domain.Comment`
  entity a post-comment is — only the parent it's scoped to differs. No
  need to duplicate the rendering logic.
  """

  defdelegate index(assigns), to: ApiWeb.CommentJSON
  defdelegate show(assigns), to: ApiWeb.CommentJSON
end
