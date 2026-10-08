defmodule Api.Usecases.ConnectionComment.UpdateConnectionComment.UpdateConnectionCommentUsecase do
  @moduledoc """
  Edits a connection-comment's body. Only the comment's author may edit it.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.ConnectionComment.UpdateConnectionComment.UpdateConnectionCommentUsecaseDto

  defstruct [:repository]

  def call(
        %UpdateConnectionCommentUsecaseDto{
          user: user,
          connection_id: connection_id,
          comment_id: comment_id,
          attrs: attrs
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.update_comment(user, connection_id, comment_id, attrs, adaptee)
  end
end
