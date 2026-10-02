defmodule Api.Usecases.PasswordReset.DeliverResetPasswordInstructions.DeliverResetPasswordInstructionsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.PasswordReset.DeliverResetPasswordInstructions.DeliverResetPasswordInstructionsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :reset_url_fun]
  defstruct [:user, :reset_url_fun]

  @type t :: %__MODULE__{user: %User{}, reset_url_fun: (String.t() -> String.t())}
end
