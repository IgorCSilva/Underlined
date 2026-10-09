defmodule Api.Usecases.Club.GetClub.GetClubUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.GetClub.GetClubUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:id]
  defstruct [:id, :current_user]

  @type t :: %__MODULE__{id: Ecto.UUID.t(), current_user: %User{} | nil}
end
