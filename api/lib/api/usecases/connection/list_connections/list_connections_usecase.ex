defmodule Api.Usecases.Connection.ListConnections.ListConnectionsUsecase do
  @moduledoc """
  Every connection involving a post, on either side. Returns `{:error,
  :not_found}` when the post doesn't exist.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Connection.ListConnections.ListConnectionsUsecaseDto

  defstruct [:repository]

  def call(%ListConnectionsUsecaseDto{id: id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_connections(id, adaptee)
  end
end
