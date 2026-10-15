defmodule Api.Usecases.Club.GetClubReadingProgress.GetClubReadingProgressUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.GetClubReadingProgress.GetClubReadingProgressUsecase`.
  """

  @enforce_keys [:user, :club_id]
  defstruct [:user, :club_id]

  @type t :: %__MODULE__{user: Api.Domain.User.t(), club_id: Ecto.UUID.t()}
end
