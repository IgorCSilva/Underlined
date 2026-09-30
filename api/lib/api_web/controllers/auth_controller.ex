defmodule ApiWeb.AuthController do
  use ApiWeb, :controller

  alias Api.Accounts

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
    with {:ok, user} <- Accounts.register_user(user_params) do
      conn
      |> put_status(:created)
      |> render(:session_user, user: user)
    end
  end

  def login(conn, %{"email" => email, "password" => password} = params) do
    remember_me? = truthy?(params["remember_me"])

    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{detail: "invalid email or password"}})

      %Accounts.User{enabled: false} ->
        conn
        |> put_status(:forbidden)
        |> json(%{errors: %{detail: "account pending confirmation"}})

      user ->
        {access_token, refresh_token} = issue_session!(user, remember_me?)

        conn
        |> put_refresh_cookie(refresh_token, remember_me?)
        |> render(:session, user: user, access_token: access_token)
    end
  end

  def refresh(conn, _params) do
    with token when is_binary(token) <- conn.cookies[@refresh_cookie],
         {:ok, access_token, refresh_token, remember_me?} <- Accounts.refresh_session(token) do
      user = Api.Accounts.Guardian.Plug.current_resource(conn) || fetch_user_from_token(access_token)

      conn
      |> put_refresh_cookie(refresh_token, remember_me?)
      |> render(:session, user: user, access_token: access_token)
    else
      _ ->
        conn
        |> delete_refresh_cookie()
        |> put_status(:unauthorized)
        |> json(%{errors: %{detail: "invalid or expired session"}})
    end
  end

  def logout(conn, _params) do
    case conn.cookies[@refresh_cookie] do
      token when is_binary(token) -> Accounts.revoke_refresh_token(token)
      _ -> :ok
    end

    conn
    |> delete_refresh_cookie()
    |> send_resp(:no_content, "")
  end

  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, user} -> render(conn, :session_user, user: user)
      {:error, :invalid_token} -> {:error, :invalid_token}
    end
  end

  def request_password_reset(conn, %{"email" => email}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(user, &reset_password_url/1)
    end

    # Always respond the same way, whether or not the email exists.
    send_resp(conn, :no_content, "")
  end

  def reset_password(conn, %{"token" => token, "password" => password}) do
    with %Accounts.User{} = user <- Accounts.get_user_by_reset_password_token(token),
         {:ok, user} <- Accounts.reset_user_password(user, %{"password" => password}) do
      render(conn, :session_user, user: user)
    else
      nil -> {:error, :invalid_token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp issue_session!(user, remember_me?) do
    {:ok, access_token, refresh_token} = Accounts.create_session(user, remember_me?)
    {access_token, refresh_token}
  end

  defp fetch_user_from_token(access_token) do
    {:ok, claims} = Api.Accounts.Guardian.decode_and_verify(access_token)
    {:ok, user} = Api.Accounts.Guardian.resource_from_claims(claims)
    user
  end

  defp put_refresh_cookie(conn, refresh_token, remember_me?) do
    max_age = if remember_me?, do: @remember_me_max_age, else: @session_max_age

    put_resp_cookie(conn, @refresh_cookie, refresh_token,
      http_only: true,
      same_site: "Lax",
      secure: secure_cookies?(),
      max_age: max_age,
      path: "/api/auth"
    )
  end

  defp delete_refresh_cookie(conn) do
    delete_resp_cookie(conn, @refresh_cookie, path: "/api/auth")
  end

  defp secure_cookies?, do: Application.get_env(:api, :env) == :prod

  defp truthy?(value), do: value in [true, "true", "1", 1]

  defp reset_password_url(token), do: "#{web_base_url()}/reset-password/#{token}"
  defp web_base_url, do: Application.get_env(:api, :web_base_url, "http://localhost:3000")
end
