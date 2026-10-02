defmodule Api.Usecases.EmailConfirmation.DeliverConfirmationInstructions.DeliverConfirmationInstructionsUsecase do
  @moduledoc """
  Emails a confirmation link built from a one-time token.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  alias Api.Usecases.EmailConfirmation.DeliverConfirmationInstructions.DeliverConfirmationInstructionsUsecaseDto

  defstruct [:repository]

  def call(
        %DeliverConfirmationInstructionsUsecaseDto{
          user: %User{} = user,
          confirmation_url_fun: confirmation_url_fun
        },
        %__MODULE__{repository: %{adapter: adapter, adaptee: adaptee}}
      )
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      encoded_token = adapter.create_email_token(user, "confirm", adaptee)
      mailer().deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  defp mailer, do: Application.get_env(:api, :mailer, Api.Infrastructure.SwooshMailer)
end
