defmodule Api.Usecases.PasswordReset.GetUserByResetPasswordToken.GetUserByResetPasswordTokenUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.PasswordReset.GetUserByResetPasswordToken.GetUserByResetPasswordTokenUsecase`.
  """

  @enforce_keys [:token]
  defstruct [:token]

  @type t :: %__MODULE__{token: String.t()}
end
