defmodule Api.Usecases.PasswordReset.GetUserByResetPasswordToken.GetUserByResetPasswordTokenUsecase do
  @moduledoc """
  Looks up the user owning a valid, unexpired password reset token.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.PasswordReset.GetUserByResetPasswordToken.GetUserByResetPasswordTokenUsecaseDto

  defstruct [:repository]

  def call(%GetUserByResetPasswordTokenUsecaseDto{token: token}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.verify_email_token(token, "reset_password", adaptee)
  end
end
