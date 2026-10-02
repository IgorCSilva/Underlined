defmodule Api.Usecases.Comment.ListComments.ListCommentsUsecase do
  @moduledoc """
  Top-level comments for a post, oldest first, each with its (also
  oldest-first) replies.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Comment.ListComments.ListCommentsUsecaseDto

  defstruct [:repository]

  def call(%ListCommentsUsecaseDto{post_id: post_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_comments(post_id, adaptee)
  end
end
