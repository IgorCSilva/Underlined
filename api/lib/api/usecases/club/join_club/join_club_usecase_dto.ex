defmodule Api.Usecases.Club.JoinClub.JoinClubUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.JoinClub.JoinClubUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :club_id]
  defstruct [:user, :club_id]

  @type t :: %__MODULE__{user: %User{}, club_id: Ecto.UUID.t()}
end
