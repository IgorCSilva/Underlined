defmodule Api.Infra.SwooshMailer do
  @moduledoc "MailerPort implementation backed by Swoosh (SMTP in dev via Mailpit, Resend in prod)."

  @behaviour Api.Ports.MailerPort

  import Swoosh.Email

  alias Api.Accounts.User

  @from {"Underlined", "hello@underlined.app"}

  @impl true
  def deliver_confirmation_instructions(%User{} = user, url) do
    new()
    |> to({user.name, user.email})
    |> from(@from)
    |> subject("Confirm your Underlined account")
    |> text_body("""
    Hi #{user.name},

    Confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.
    """)
    |> deliver()
  end

  @impl true
  def deliver_reset_password_instructions(%User{} = user, url) do
    new()
    |> to({user.name, user.email})
    |> from(@from)
    |> subject("Reset your Underlined password")
    |> text_body("""
    Hi #{user.name},

    Reset your password by visiting the URL below:

    #{url}

    If you didn't request this, please ignore this.
    """)
    |> deliver()
  end

  defp deliver(email) do
    Api.Mailer.deliver(email)
  end
end
