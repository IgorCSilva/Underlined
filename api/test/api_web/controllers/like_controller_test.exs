defmodule ApiWeb.LikeControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Accounts
  alias Api.Catalog
  alias Api.Posts

  setup :verify_on_exit!

  setup do
    Api.MailerMock |> stub(:deliver_confirmation_instructions, fn _user, _url -> {:ok, :delivered} end)

    {:ok, author} =
      Accounts.register_user(%{"email" => "author@example.com", "password" => "supersecret", "name" => "Author"})

    {:ok, liker} =
      Accounts.register_user(%{"email" => "liker@example.com", "password" => "supersecret", "name" => "Liker"})

    {:ok, access_token, _refresh_token} = Accounts.create_session(liker, false)
    {:ok, book} = Catalog.add_book(%{"title" => "Sapiens", "author" => "Yuval Noah Harari"})

    {:ok, post} =
      Posts.create_post(author, %{
        "book_id" => book.id,
        "passage_text" => "A short passage.",
        "thinking" => "This changed how I think."
      })

    %{post: post, access_token: access_token}
  end

  describe "POST /api/posts/:post_id/likes" do
    test "likes the post when authenticated", %{conn: conn, post: post, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post.id}/likes")

      assert json_response(conn, 200) == %{"data" => %{"liked" => true, "like_count" => 1}}
    end

    test "liking twice stays at a like_count of 1", %{conn: conn, post: post, access_token: token} do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      post(conn, ~p"/api/posts/#{post.id}/likes")
      conn2 = post(conn, ~p"/api/posts/#{post.id}/likes")

      assert json_response(conn2, 200) == %{"data" => %{"liked" => true, "like_count" => 1}}
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post} do
      conn = post(conn, ~p"/api/posts/#{post.id}/likes")
      assert json_response(conn, 401)
    end

    test "returns 404 for an unknown post", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{Ecto.UUID.generate()}/likes")

      assert json_response(conn, 404)
    end
  end

  describe "DELETE /api/posts/:post_id/likes" do
    test "unlikes a liked post", %{conn: conn, post: post, access_token: token} do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")
      post(conn, ~p"/api/posts/#{post.id}/likes")

      conn2 = delete(conn, ~p"/api/posts/#{post.id}/likes")
      assert json_response(conn2, 200) == %{"data" => %{"liked" => false, "like_count" => 0}}
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post} do
      conn = delete(conn, ~p"/api/posts/#{post.id}/likes")
      assert json_response(conn, 401)
    end
  end
end
