defmodule Api.Usecases.ConnectionComment.CreateConnectionComment.CreateConnectionCommentUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.ConnectionComment.CreateConnectionComment.CreateConnectionCommentUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :connection_id, :attrs]
  defstruct [:user, :connection_id, :attrs]

  @type t :: %__MODULE__{user: User.t(), connection_id: Ecto.UUID.t(), attrs: map()}
end
