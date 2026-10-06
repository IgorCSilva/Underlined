defmodule ApiWeb.BookmarkControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Adapters.Posts
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
  alias Api.Usecases.Post.CreatePost.CreatePostUsecaseDto
  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  setup :verify_on_exit!

  setup do
    Api.MailerMock
    |> stub(:deliver_confirmation_instructions, fn _user, _url -> {:ok, :delivered} end)

    {:ok, author} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "author@example.com", "password" => "supersecret", "name" => "Author"}
      })

    {:ok, saver} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "saver@example.com", "password" => "supersecret", "name" => "Saver"}
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: saver, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    {:ok, post} =
      Posts.create_post(%CreatePostUsecaseDto{
        user: author,
        attrs: %{
          "book_id" => book.id,
          "passage_text" => "A short passage.",
          "thinking" => "This changed how I think."
        }
      })

    %{post: post, access_token: access_token, author: author}
  end

  describe "POST /api/posts/:post_id/bookmarks" do
    test "bookmarks the post when authenticated", %{conn: conn, post: post, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post.id}/bookmarks")

      assert json_response(conn, 200) == %{"data" => %{"bookmarked" => true}}
    end

    test "bookmarking twice stays bookmarked, not duplicated", %{
      conn: conn,
      post: post,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      post(conn, ~p"/api/posts/#{post.id}/bookmarks")
      conn2 = post(conn, ~p"/api/posts/#{post.id}/bookmarks")

      assert json_response(conn2, 200) == %{"data" => %{"bookmarked" => true}}
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post} do
      conn = post(conn, ~p"/api/posts/#{post.id}/bookmarks")
      assert json_response(conn, 401)
    end

    test "returns 404 for an unknown post", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{Ecto.UUID.generate()}/bookmarks")

      assert json_response(conn, 404)
    end
  end

  describe "DELETE /api/posts/:post_id/bookmarks" do
    test "unbookmarks a bookmarked post", %{conn: conn, post: post, access_token: token} do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")
      post(conn, ~p"/api/posts/#{post.id}/bookmarks")

      conn2 = delete(conn, ~p"/api/posts/#{post.id}/bookmarks")
      assert json_response(conn2, 200) == %{"data" => %{"bookmarked" => false}}
    end

    test "unbookmarking a post that was never bookmarked is a no-op", %{
      conn: conn,
      post: post,
      access_token: token
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/posts/#{post.id}/bookmarks")

      assert json_response(conn, 200) == %{"data" => %{"bookmarked" => false}}
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post} do
      conn = delete(conn, ~p"/api/posts/#{post.id}/bookmarks")
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/me/bookmarks" do
    test "lists only the current user's bookmarked posts, newest first", %{
      conn: conn,
      post: post,
      access_token: token,
      author: author
    } do
      {:ok, book2} =
        Catalog.add_book(%AddBookUsecaseDto{attrs: %{"title" => "1984", "author" => "George Orwell"}})

      {:ok, other_post} =
        Posts.create_post(%CreatePostUsecaseDto{
          user: author,
          attrs: %{
            "book_id" => book2.id,
            "passage_text" => "Another passage.",
            "thinking" => "Another thought."
          }
        })

      conn = conn |> put_req_header("authorization", "Bearer #{token}")
      post(conn, ~p"/api/posts/#{post.id}/bookmarks")
      post(conn, ~p"/api/posts/#{other_post.id}/bookmarks")

      conn2 = get(conn, ~p"/api/me/bookmarks")

      assert %{"data" => [first, second]} = json_response(conn2, 200)
      assert first["id"] == other_post.id
      assert first["bookmarked_by_user"] == true
      assert second["id"] == post.id
      assert second["bookmarked_by_user"] == true
    end

    test "does not include a post the user hasn't bookmarked", %{
      conn: conn,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")
      conn2 = get(conn, ~p"/api/me/bookmarks")

      assert json_response(conn2, 200) == %{"data" => []}
    end

    test "rejects an unauthenticated request", %{conn: conn} do
      conn = get(conn, ~p"/api/me/bookmarks")
      assert json_response(conn, 401)
    end
  end
end
