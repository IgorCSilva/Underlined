defmodule ApiWeb.ProfileControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  setup :verify_on_exit!

  setup do
    Api.MailerMock
    |> stub(:deliver_confirmation_instructions, fn _user, _url -> {:ok, :delivered} end)

    {:ok, user} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{
          "email" => "reader@example.com",
          "password" => "supersecret",
          "name" => "Reader One"
        }
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: user, remember_me: false})

    %{user: user, access_token: access_token}
  end

  describe "GET /api/users/:id" do
    test "returns a user's public profile", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}")

      assert %{"data" => %{"id" => id, "name" => "Reader One", "followed_by_user" => false}} =
               json_response(conn, 200)

      assert id == user.id
    end

    test "returns 404 for an unknown user", %{conn: conn} do
      conn = get(conn, ~p"/api/users/999999")
      assert json_response(conn, 404)
    end

    test "reports followed_by_user true once the caller follows them", %{conn: conn, user: user} do
      {:ok, viewer} =
        Accounts.register_user(%RegisterUserUsecaseDto{
          attrs: %{
            "email" => "viewer@example.com",
            "password" => "supersecret",
            "name" => "Viewer"
          }
        })

      {:ok, viewer_token, _refresh_token} =
        Accounts.create_session(%CreateSessionUsecaseDto{user: viewer, remember_me: false})

      follow_conn =
        conn
        |> put_req_header("authorization", "Bearer #{viewer_token}")
        |> post(~p"/api/users/#{user.id}/follow")

      assert json_response(follow_conn, 200)

      authed_show =
        build_conn()
        |> put_req_header("authorization", "Bearer #{viewer_token}")
        |> get(~p"/api/users/#{user.id}")

      assert %{"data" => %{"followed_by_user" => true}} = json_response(authed_show, 200)

      anon_show = get(build_conn(), ~p"/api/users/#{user.id}")
      assert %{"data" => %{"followed_by_user" => false}} = json_response(anon_show, 200)
    end
  end

  describe "PUT /api/me" do
    test "picks one of the fixed preset avatars", %{conn: conn, access_token: token} do
      [preset | _] = Api.Infrastructure.Repository.User.Postgres.User.avatar_choices()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me", user: %{avatar_url: preset})

      assert %{"data" => %{"avatar_url" => ^preset}} = json_response(conn, 200)
    end

    test "rejects an avatar_url outside the preset list", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me", user: %{avatar_url: "https://evil.example/x.png"})

      assert json_response(conn, 422)
    end
  end

  describe "PUT /api/me/avatar" do
    test "uploads an avatar and updates the profile", %{
      conn: conn,
      user: user,
      access_token: token
    } do
      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, "image/png" ->
        assert id == user.id
        {:ok, "http://minio/avatars/#{id}.png"}
      end)

      path = Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.png")
      File.write!(path, "fake-png-bytes")

      upload = %Plug.Upload{path: path, filename: "avatar.png", content_type: "image/png"}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me/avatar", avatar: upload)

      assert %{"data" => %{"avatar_url" => "http://minio/avatars/" <> _}} =
               json_response(conn, 200)
    end

    test "deletes the previous avatar object when a second upload succeeds", %{
      conn: conn,
      user: user,
      access_token: token
    } do
      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-1.png"}
      end)

      path1 =
        Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.png")

      File.write!(path1, "fake-png-bytes-1")
      upload1 = %Plug.Upload{path: path1, filename: "avatar.png", content_type: "image/png"}

      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/me/avatar", avatar: upload1)
      |> json_response(200)

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-2.png"}
      end)
      |> expect(:delete_avatar, fn url ->
        assert url == "http://minio/avatars/#{user.id}-1.png"
        :ok
      end)

      path2 =
        Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.png")

      File.write!(path2, "fake-png-bytes-2")
      upload2 = %Plug.Upload{path: path2, filename: "avatar.png", content_type: "image/png"}

      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/me/avatar", avatar: upload2)
      |> json_response(200)
    end

    test "rejects a disallowed content type", %{conn: conn, access_token: token} do
      path = Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.txt")
      File.write!(path, "not an image")
      upload = %Plug.Upload{path: path, filename: "avatar.txt", content_type: "text/plain"}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me/avatar", avatar: upload)

      assert json_response(conn, 422)
    end
  end
end
