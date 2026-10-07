defmodule ApiWeb.AuthController do
  use ApiWeb, :controller
  import ApiWeb.Gettext

  alias Api.Adapters.Accounts
  alias Api.Infrastructure.Repository.User.Postgres.User

  alias Api.Usecases.EmailConfirmation.ConfirmUser.ConfirmUserUsecaseDto

  alias Api.Usecases.PasswordReset.DeliverResetPasswordInstructions.DeliverResetPasswordInstructionsUsecaseDto

  alias Api.Usecases.PasswordReset.GetUserByResetPasswordToken.GetUserByResetPasswordTokenUsecaseDto

  alias Api.Usecases.PasswordReset.ResetUserPassword.ResetUserPasswordUsecaseDto

  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto
  alias Api.Usecases.Session.RefreshSession.RefreshSessionUsecaseDto
  alias Api.Usecases.Session.RevokeRefreshToken.RevokeRefreshTokenUsecaseDto

  alias Api.Usecases.User.GetUserByEmail.GetUserByEmailUsecaseDto
  alias Api.Usecases.User.GetUserByEmailAndPassword.GetUserByEmailAndPasswordUsecaseDto
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  @refresh_cookie "refresh_token"
  @session_max_age 60 * 60 * 24
  @remember_me_max_age 60 * 60 * 24 * 30

  action_fallback ApiWeb.FallbackController

  # Email delivery is disabled for now (no verified sending domain yet — see
  # deploy/specifications.md). Registration still creates the user, but
  # `enabled` starts false and is flipped manually in the database once the
  # responsible party confirms the email address by hand; the existing
  # token-based confirmation code below is kept for when real sending comes
  # back, it's just not invoked from here.
  def register(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.register_user(%RegisterUserUsecaseDto{attrs: user_params}) do
      conn
      |> put_status(:created)
      |> render(:session_user, user: user)
    end
  end

  def login(conn, %{"email" => email, "password" => password} = params) do
    remember_me? = truthy?(params["remember_me"])

    dto = %GetUserByEmailAndPasswordUsecaseDto{email: email, password: password}

    case Accounts.get_user_by_email_and_password(dto) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          errors: %{detail: gettext("invalid email or password"), code: "invalid_credentials"}
        })

      %User{enabled: false} ->
        conn
        |> put_status(:forbidden)
        |> json(%{
          errors: %{
            detail: gettext("account pending confirmation"),
            code: "account_pending_confirmation"
          }
        })

      user ->
        {access_token, refresh_token} = issue_session!(user, remember_me?)

        conn
        |> put_refresh_cookie(refresh_token, remember_me?)
        |> render(:session, user: user, access_token: access_token)
    end
  end

  def refresh(conn, _params) do
    with token when is_binary(token) <- conn.cookies[@refresh_cookie],
         {:ok, access_token, refresh_token, remember_me?} <-
           Accounts.refresh_session(%RefreshSessionUsecaseDto{refresh_token: token}) do
      user =
        Api.Infrastructure.Guardian.Plug.current_resource(conn) ||
          fetch_user_from_token(access_token)

      conn
      |> put_refresh_cookie(refresh_token, remember_me?)
      |> render(:session, user: user, access_token: access_token)
    else
      # Deliberately does NOT delete the cookie here: the refresh token is
      # rotated on every successful call, so two refresh requests racing on
      # the same (about-to-be-rotated) cookie value is expected under normal
      # use (e.g. several components independently reacting to an expired
      # access token). The loser must not be able to delete a cookie the
      # winner just legitimately set — that would log the user out of a
      # perfectly valid session. Only an explicit logout deletes the cookie;
      # a genuinely dead cookie here just keeps failing harmlessly.
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          errors: %{detail: gettext("invalid or expired session"), code: "invalid_session"}
        })
    end
  end

  def logout(conn, _params) do
    case conn.cookies[@refresh_cookie] do
      token when is_binary(token) ->
        Accounts.revoke_refresh_token(%RevokeRefreshTokenUsecaseDto{refresh_token: token})

      _ ->
        :ok
    end

    conn
    |> delete_refresh_cookie()
    |> send_resp(:no_content, "")
  end

  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(%ConfirmUserUsecaseDto{token: token}) do
      {:ok, user} -> render(conn, :session_user, user: user)
      {:error, :invalid_token} -> {:error, :invalid_token}
    end
  end

  def request_password_reset(conn, %{"email" => email}) do
    if user = Accounts.get_user_by_email(%GetUserByEmailUsecaseDto{email: email}) do
      dto = %DeliverResetPasswordInstructionsUsecaseDto{
        user: user,
        reset_url_fun: &reset_password_url/1
      }

      Accounts.deliver_user_reset_password_instructions(dto)
    end

    # Always respond the same way, whether or not the email exists.
    send_resp(conn, :no_content, "")
  end

  def reset_password(conn, %{"token" => token, "password" => password}) do
    with %User{} = user <-
           Accounts.get_user_by_reset_password_token(%GetUserByResetPasswordTokenUsecaseDto{
             token: token
           }),
         {:ok, user} <-
           Accounts.reset_user_password(%ResetUserPasswordUsecaseDto{
             user: user,
             attrs: %{"password" => password}
           }) do
      render(conn, :session_user, user: user)
    else
      nil -> {:error, :invalid_token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp issue_session!(user, remember_me?) do
    {:ok, access_token, refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: user, remember_me: remember_me?})

    {access_token, refresh_token}
  end

  defp fetch_user_from_token(access_token) do
    {:ok, claims} = Api.Infrastructure.Guardian.decode_and_verify(access_token)
    {:ok, user} = Api.Infrastructure.Guardian.resource_from_claims(claims)
    user
  end

  defp put_refresh_cookie(conn, refresh_token, remember_me?) do
    max_age = if remember_me?, do: @remember_me_max_age, else: @session_max_age

    put_resp_cookie(conn, @refresh_cookie, refresh_token,
      http_only: true,
      same_site: same_site_policy(),
      secure: secure_cookies?(),
      max_age: max_age,
      path: "/api/auth"
    )
  end

  defp delete_refresh_cookie(conn) do
    delete_resp_cookie(conn, @refresh_cookie,
      path: "/api/auth",
      same_site: same_site_policy(),
      secure: secure_cookies?()
    )
  end

  defp secure_cookies?, do: Application.get_env(:api, :env) == :prod

  # The frontend and API are served from different origins in production, so
  # the refresh cookie needs SameSite=None (which browsers only honor when
  # Secure is also set) to survive cross-site fetch requests. Locally both
  # run on localhost (same "site", just different ports), and requiring
  # Secure there would mean dev needs HTTPS just to keep a session.
  defp same_site_policy, do: if(secure_cookies?(), do: "None", else: "Lax")

  defp truthy?(value), do: value in [true, "true", "1", 1]

  defp reset_password_url(token), do: "#{web_base_url()}/reset-password/#{token}"
  defp web_base_url, do: Application.get_env(:api, :web_base_url, "http://localhost:3000")
end
