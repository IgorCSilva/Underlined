defmodule Api.Usecases.PasswordReset.ResetUserPassword.ResetUserPasswordUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.PasswordReset.ResetUserPassword.ResetUserPasswordUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :attrs]
  defstruct [:user, :attrs]

  @type t :: %__MODULE__{user: %User{}, attrs: map()}
end
