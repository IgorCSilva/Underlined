defmodule Api.Usecases.Comment.UpdateComment.UpdateCommentUsecase do
  @moduledoc """
  Edits a comment's body. Only the comment's author may edit it.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Comment.UpdateComment.UpdateCommentUsecaseDto

  defstruct [:repository]

  def call(
        %UpdateCommentUsecaseDto{
          user: %User{} = user,
          post_id: post_id,
          comment_id: comment_id,
          attrs: attrs
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.update_comment(user, post_id, comment_id, attrs, adaptee)
  end
end
