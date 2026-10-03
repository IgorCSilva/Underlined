defmodule Api.Infrastructure.SwooshMailer do
  @moduledoc "MailerPort implementation backed by Swoosh (SMTP in dev via Mailpit, Resend in prod)."

  @behaviour Api.Adapters.MailerPort

  import Swoosh.Email
  import ApiWeb.Gettext

  alias Api.Infrastructure.Repository.User.Postgres.User

  @from {"Underlined", "hello@underlined.app"}

  @impl true
  def deliver_confirmation_instructions(%User{} = user, url) do
    new()
    |> to({user.name, user.email})
    |> from(@from)
    |> subject(gettext("Confirm your Underlined account"))
    |> text_body(
      gettext(
        """
        Hi %{name},

        Confirm your account by visiting the URL below:

        %{url}

        If you didn't create an account with us, please ignore this.
        """,
        name: user.name,
        url: url
      )
    )
    |> deliver()
  end

  @impl true
  def deliver_reset_password_instructions(%User{} = user, url) do
    new()
    |> to({user.name, user.email})
    |> from(@from)
    |> subject(gettext("Reset your Underlined password"))
    |> text_body(
      gettext(
        """
        Hi %{name},

        Reset your password by visiting the URL below:

        %{url}

        If you didn't request this, please ignore this.
        """,
        name: user.name,
        url: url
      )
    )
    |> deliver()
  end

  defp deliver(email) do
    Api.Mailer.deliver(email)
  end
end
