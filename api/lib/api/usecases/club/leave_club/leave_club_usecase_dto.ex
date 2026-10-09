defmodule Api.Usecases.Club.LeaveClub.LeaveClubUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.LeaveClub.LeaveClubUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :club_id]
  defstruct [:user, :club_id]

  @type t :: %__MODULE__{user: %User{}, club_id: Ecto.UUID.t()}
end
