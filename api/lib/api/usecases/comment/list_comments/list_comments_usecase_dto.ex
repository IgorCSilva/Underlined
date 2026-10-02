defmodule Api.Usecases.Comment.ListComments.ListCommentsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Comment.ListComments.ListCommentsUsecase`.
  """

  @enforce_keys [:post_id]
  defstruct [:post_id]

  @type t :: %__MODULE__{post_id: Ecto.UUID.t()}
end
