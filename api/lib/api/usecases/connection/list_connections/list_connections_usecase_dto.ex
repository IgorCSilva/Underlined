defmodule Api.Usecases.Connection.ListConnections.ListConnectionsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Connection.ListConnections.ListConnectionsUsecase`.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: Ecto.UUID.t()}
end
