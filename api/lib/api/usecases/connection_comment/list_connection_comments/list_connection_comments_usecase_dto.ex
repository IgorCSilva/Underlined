defmodule Api.Usecases.ConnectionComment.ListConnectionComments.ListConnectionCommentsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.ConnectionComment.ListConnectionComments.ListConnectionCommentsUsecase`.
  """

  @enforce_keys [:connection_id]
  defstruct [:connection_id]

  @type t :: %__MODULE__{connection_id: Ecto.UUID.t()}
end
