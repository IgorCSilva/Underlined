defmodule Api.Usecases.Club.ListClubComments.ListClubCommentsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.ListClubComments.ListClubCommentsUsecase`.
  """

  @enforce_keys [:club_post_id]
  defstruct [:club_post_id]

  @type t :: %__MODULE__{club_post_id: Ecto.UUID.t()}
end
