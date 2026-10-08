defmodule Api.Usecases.ConnectionComment.ListConnectionComments.ListConnectionCommentsUsecase do
  @moduledoc """
  Top-level comments for a connection's debate thread, oldest first, each
  with its (also oldest-first) replies.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.ConnectionComment.ListConnectionComments.ListConnectionCommentsUsecaseDto

  defstruct [:repository]

  def call(%ListConnectionCommentsUsecaseDto{connection_id: connection_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_comments(connection_id, adaptee)
  end
end
