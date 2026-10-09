defmodule Api.Usecases.Club.CreateClub.CreateClubUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Club.CreateClub.CreateClubUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:creator, :attrs]
  defstruct [:creator, :attrs]

  @type t :: %__MODULE__{creator: %User{}, attrs: map()}
end
