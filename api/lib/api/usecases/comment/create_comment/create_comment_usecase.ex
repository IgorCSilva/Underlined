defmodule Api.Usecases.Comment.CreateComment.CreateCommentUsecase do
  @moduledoc """
  Creates a top-level comment (no `parent_comment_id`) or a reply (one
  level deep only) on a post.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Comment.CreateComment.CreateCommentUsecaseDto

  defstruct [:repository]

  def call(
        %CreateCommentUsecaseDto{user: %User{} = user, post_id: post_id, attrs: attrs},
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.create_comment(user, post_id, attrs, adaptee)
  end
end
