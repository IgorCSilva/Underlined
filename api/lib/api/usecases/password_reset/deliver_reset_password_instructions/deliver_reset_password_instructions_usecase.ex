defmodule Api.Usecases.PasswordReset.DeliverResetPasswordInstructions.DeliverResetPasswordInstructionsUsecase do
  @moduledoc """
  Emails a password reset link built from a one-time token.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  alias Api.Usecases.PasswordReset.DeliverResetPasswordInstructions.DeliverResetPasswordInstructionsUsecaseDto

  defstruct [:repository]

  def call(
        %DeliverResetPasswordInstructionsUsecaseDto{
          user: %User{} = user,
          reset_url_fun: reset_url_fun
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      )
      when is_function(reset_url_fun, 1) do
    encoded_token = adapter.create_email_token(user, "reset_password", adaptee)
    mailer().deliver_reset_password_instructions(user, reset_url_fun.(encoded_token))
  end

  defp mailer, do: Application.get_env(:api, :mailer, Api.Infrastructure.SwooshMailer)
end
