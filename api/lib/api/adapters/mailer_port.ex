defmodule Api.Adapters.MailerPort do
  @moduledoc "Behaviour for sending transactional account emails."

  alias Api.Infrastructure.Repository.User.Postgres.User

  @callback deliver_confirmation_instructions(User.t(), String.t()) ::
              {:ok, term()} | {:error, term()}
  @callback deliver_reset_password_instructions(User.t(), String.t()) ::
              {:ok, term()} | {:error, term()}
end
