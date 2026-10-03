defmodule ApiWeb.AuthControllerTest do
  use ApiWeb.ConnCase, async: true

  alias Api.Adapters.Accounts
  alias Api.Repo
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  @user_attrs %{
    "email" => "reader@example.com",
    "password" => "supersecret",
    "name" => "Reader One"
  }

  defp register_user(conn) do
    post(conn, ~p"/api/auth/register", user: @user_attrs)
  end

  # Registration leaves new accounts disabled (see AuthController.register);
  # this simulates the responsible party's manual DB flip after confirming
  # the email address by hand.
  defp create_enabled_user(attrs \\ @user_attrs) do
    {:ok, user} = Accounts.register_user(%RegisterUserUsecaseDto{attrs: attrs})
    user |> Ecto.Changeset.change(enabled: true) |> Repo.update!()
  end

  describe "POST /api/auth/register" do
    test "creates a disabled user and does not start a session", %{conn: conn} do
      conn = register_user(conn)

      assert %{"data" => user} = json_response(conn, 201)
      assert user["email"] == "reader@example.com"
      refute Map.has_key?(user, "password")
      refute Map.has_key?(user, "access_token")
      refute conn.resp_cookies["refresh_token"]
    end

    test "returns 422 for a duplicate email", %{conn: conn} do
      conn = register_user(conn)
      assert conn.status == 201

      conn2 = register_user(build_conn())
      assert %{"errors" => %{"email" => ["has already been taken"]}} = json_response(conn2, 422)
    end

    test "translates changeset validation errors to pt_BR when requested", %{conn: conn} do
      conn = register_user(conn)
      assert conn.status == 201

      conn2 = build_conn() |> put_locale("pt-BR") |> register_user()
      assert %{"errors" => %{"email" => ["já está em uso"]}} = json_response(conn2, 422)
    end
  end

  describe "POST /api/auth/login" do
    setup do
      %{user: create_enabled_user()}
    end

    test "returns an access token and refresh cookie for valid credentials", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login", email: "reader@example.com", password: "supersecret")

      assert %{"data" => %{"access_token" => access_token}} = json_response(conn, 200)
      assert is_binary(access_token)
      assert conn.resp_cookies["refresh_token"]
    end

    test "returns 401 for an invalid password", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/login", email: "reader@example.com", password: "wrong")

      assert %{"errors" => %{"code" => "invalid_credentials", "detail" => "invalid email or password"}} =
               json_response(conn, 401)
    end

    test "translates the error detail to pt_BR when requested", %{conn: conn} do
      conn =
        conn
        |> put_locale("pt-BR")
        |> post(~p"/api/auth/login", email: "reader@example.com", password: "wrong")

      assert %{"errors" => %{"code" => "invalid_credentials", "detail" => "e-mail ou senha inválidos"}} =
               json_response(conn, 401)
    end

    test "returns 403 for an account that hasn't been enabled yet", %{conn: conn} do
      attrs = %{@user_attrs | "email" => "pending@example.com"}
      {:ok, _user} = Accounts.register_user(%RegisterUserUsecaseDto{attrs: attrs})

      conn =
        post(conn, ~p"/api/auth/login", email: "pending@example.com", password: "supersecret")

      assert json_response(conn, 403)
      refute conn.resp_cookies["refresh_token"]
    end
  end

  describe "POST /api/auth/refresh and DELETE /api/auth/logout" do
    setup %{conn: conn} do
      create_enabled_user()
      conn = post(conn, ~p"/api/auth/login", email: "reader@example.com", password: "supersecret")
      %{"data" => %{"access_token" => access_token}} = json_response(conn, 200)
      %{conn: conn, access_token: access_token}
    end

    test "refresh rotates the refresh cookie and returns a new access token", %{conn: conn} do
      refresh_cookie = conn.resp_cookies["refresh_token"].value

      conn =
        build_conn()
        |> put_req_cookie("refresh_token", refresh_cookie)
        |> post(~p"/api/auth/refresh")

      assert %{"data" => %{"access_token" => new_access_token}} = json_response(conn, 200)
      assert is_binary(new_access_token)
      assert conn.resp_cookies["refresh_token"].value != refresh_cookie
    end

    test "refresh fails once the refresh token has been revoked (logout)", %{conn: conn} do
      refresh_cookie = conn.resp_cookies["refresh_token"].value

      build_conn()
      |> put_req_cookie("refresh_token", refresh_cookie)
      |> delete(~p"/api/auth/logout")
      |> response(204)

      conn =
        build_conn()
        |> put_req_cookie("refresh_token", refresh_cookie)
        |> post(~p"/api/auth/refresh")

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/auth/refresh carries \"remember me\" forward" do
    setup do
      create_enabled_user()
      :ok
    end

    test "keeps the 30-day cookie lifetime across a rotation", %{conn: conn} do
      login_conn =
        post(conn, ~p"/api/auth/login",
          email: "reader@example.com",
          password: "supersecret",
          remember_me: true
        )

      assert login_conn.resp_cookies["refresh_token"].max_age == 60 * 60 * 24 * 30
      refresh_cookie = login_conn.resp_cookies["refresh_token"].value

      refreshed_conn =
        build_conn()
        |> put_req_cookie("refresh_token", refresh_cookie)
        |> post(~p"/api/auth/refresh")

      assert json_response(refreshed_conn, 200)
      assert refreshed_conn.resp_cookies["refresh_token"].max_age == 60 * 60 * 24 * 30
    end

    test "keeps the 1-day cookie lifetime across a rotation when not remembered", %{conn: conn} do
      login_conn =
        post(conn, ~p"/api/auth/login", email: "reader@example.com", password: "supersecret")

      assert login_conn.resp_cookies["refresh_token"].max_age == 60 * 60 * 24
      refresh_cookie = login_conn.resp_cookies["refresh_token"].value

      refreshed_conn =
        build_conn()
        |> put_req_cookie("refresh_token", refresh_cookie)
        |> post(~p"/api/auth/refresh")

      assert json_response(refreshed_conn, 200)
      assert refreshed_conn.resp_cookies["refresh_token"].max_age == 60 * 60 * 24
    end
  end

  describe "GET/PUT /api/me" do
    setup %{conn: conn} do
      create_enabled_user()
      conn = post(conn, ~p"/api/auth/login", email: "reader@example.com", password: "supersecret")
      %{"data" => %{"access_token" => access_token}} = json_response(conn, 200)
      %{access_token: access_token}
    end

    test "requires authentication", %{conn: conn} do
      conn = get(conn, ~p"/api/me")
      assert json_response(conn, 401)
    end

    test "returns the current user's profile when authenticated", %{
      conn: conn,
      access_token: token
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/me")

      assert %{"data" => %{"email" => "reader@example.com", "name" => "Reader One"}} =
               json_response(conn, 200)
    end

    test "updates name and bio", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me", user: %{"name" => "New Name", "bio" => "Avid reader"})

      assert %{"data" => %{"name" => "New Name", "bio" => "Avid reader"}} =
               json_response(conn, 200)
    end
  end
end
