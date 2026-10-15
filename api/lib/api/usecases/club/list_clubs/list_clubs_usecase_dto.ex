defmodule Api.Usecases.Club.ListClubs.ListClubsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.ListClubs.ListClubsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  defstruct [:current_user]

  @type t :: %__MODULE__{current_user: %User{} | nil}
end
