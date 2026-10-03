defmodule ApiWeb.FollowControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  setup :verify_on_exit!

  setup do
    Api.MailerMock
    |> stub(:deliver_confirmation_instructions, fn _user, _url -> {:ok, :delivered} end)

    {:ok, followee} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{
          "email" => "followee@example.com",
          "password" => "supersecret",
          "name" => "Followee"
        }
      })

    {:ok, follower} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{
          "email" => "follower@example.com",
          "password" => "supersecret",
          "name" => "Follower"
        }
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: follower, remember_me: false})

    %{followee: followee, access_token: access_token}
  end

  describe "POST /api/users/:id/follow" do
    test "follows the user when authenticated", %{
      conn: conn,
      followee: followee,
      access_token: token
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/users/#{followee.id}/follow")

      assert json_response(conn, 200) == %{"data" => %{"following" => true}}
    end

    test "following twice stays following", %{conn: conn, followee: followee, access_token: token} do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      post(conn, ~p"/api/users/#{followee.id}/follow")
      conn2 = post(conn, ~p"/api/users/#{followee.id}/follow")

      assert json_response(conn2, 200) == %{"data" => %{"following" => true}}
    end

    test "rejects an unauthenticated request", %{conn: conn, followee: followee} do
      conn = post(conn, ~p"/api/users/#{followee.id}/follow")
      assert json_response(conn, 401)
    end

    test "returns 404 for an unknown user", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/users/#{Ecto.UUID.generate()}/follow")

      assert json_response(conn, 404)
    end

    test "rejects following yourself", %{conn: conn, access_token: token} do
      {:ok, claims} = Api.Infrastructure.Guardian.decode_and_verify(token)
      follower_id = claims["sub"]

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/users/#{follower_id}/follow")

      assert %{"errors" => %{"code" => "cannot_follow_self", "detail" => "can't follow yourself"}} =
               json_response(conn, 422)
    end

    test "translates the follow-yourself error to pt_BR when requested", %{
      conn: conn,
      access_token: token
    } do
      {:ok, claims} = Api.Infrastructure.Guardian.decode_and_verify(token)
      follower_id = claims["sub"]

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_locale("pt-BR")
        |> post(~p"/api/users/#{follower_id}/follow")

      assert %{
               "errors" => %{
                 "code" => "cannot_follow_self",
                 "detail" => "você não pode seguir a si mesmo"
               }
             } = json_response(conn, 422)
    end
  end

  describe "DELETE /api/users/:id/follow" do
    test "unfollows a followed user", %{conn: conn, followee: followee, access_token: token} do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")
      post(conn, ~p"/api/users/#{followee.id}/follow")

      conn2 = delete(conn, ~p"/api/users/#{followee.id}/follow")
      assert json_response(conn2, 200) == %{"data" => %{"following" => false}}
    end

    test "rejects an unauthenticated request", %{conn: conn, followee: followee} do
      conn = delete(conn, ~p"/api/users/#{followee.id}/follow")
      assert json_response(conn, 401)
    end
  end
end
