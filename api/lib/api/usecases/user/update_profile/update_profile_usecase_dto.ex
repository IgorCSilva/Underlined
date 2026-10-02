defmodule Api.Usecases.User.UpdateProfile.UpdateProfileUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.User.UpdateProfile.UpdateProfileUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :attrs]
  defstruct [:user, :attrs]

  @type t :: %__MODULE__{user: %User{}, attrs: map()}
end
