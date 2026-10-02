defmodule Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Session.CreateSession.CreateSessionUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user]
  defstruct [:user, remember_me: false]

  @type t :: %__MODULE__{user: %User{}, remember_me: boolean()}
end
