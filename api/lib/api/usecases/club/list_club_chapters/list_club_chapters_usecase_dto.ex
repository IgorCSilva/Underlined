defmodule Api.Usecases.Club.ListClubChapters.ListClubChaptersUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.ListClubChapters.ListClubChaptersUsecase`.
  """

  @enforce_keys [:club_id]
  defstruct [:club_id]

  @type t :: %__MODULE__{club_id: Ecto.UUID.t()}
end
