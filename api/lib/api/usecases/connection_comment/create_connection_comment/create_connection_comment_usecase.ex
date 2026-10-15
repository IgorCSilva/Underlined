defmodule Api.Usecases.ConnectionComment.CreateConnectionComment.CreateConnectionCommentUsecase do
  @moduledoc """
  Creates a top-level comment (no `parent_comment_id`) or a reply (one
  level deep only) on the discussion thread scoped to a connection (the
  Step 16 debate view) rather than to either post it links.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`. Unlike
  `CreateCommentUsecase`, this step has no Community Health pairing, so
  there's no event to enqueue here.
  """

  alias Api.Usecases.ConnectionComment.CreateConnectionComment.CreateConnectionCommentUsecaseDto

  defstruct [:repository]

  def call(
        %CreateConnectionCommentUsecaseDto{
          user: user,
          connection_id: connection_id,
          attrs: attrs
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      ) do
    adapter.create_comment(user, connection_id, attrs, adaptee)
  end
end
