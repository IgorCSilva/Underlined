defmodule Api.Usecases.ConnectionComment.UpdateConnectionComment.UpdateConnectionCommentUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.ConnectionComment.UpdateConnectionComment.UpdateConnectionCommentUsecase`.
  """

  alias Api.Domain.User

  @enforce_keys [:user, :connection_id, :comment_id, :attrs]
  defstruct [:user, :connection_id, :comment_id, :attrs]

  @type t :: %__MODULE__{
          user: User.t(),
          connection_id: Ecto.UUID.t(),
          comment_id: Ecto.UUID.t(),
          attrs: map()
        }
end
