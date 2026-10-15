defmodule Api.Usecases.Club.SetClubReadingProgress.SetClubReadingProgressUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.SetClubReadingProgress.SetClubReadingProgressUsecase`.
  """

  @enforce_keys [:user, :club_id]
  defstruct [:user, :club_id, :chapter_id]

  @type t :: %__MODULE__{
          user: Api.Domain.User.t(),
          club_id: Ecto.UUID.t(),
          chapter_id: Ecto.UUID.t() | nil
        }
end
