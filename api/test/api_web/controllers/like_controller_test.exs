defmodule ApiWeb.LikeControllerTest do
  use ApiWeb.ConnCase, async: true
  use Oban.Testing, repo: Api.Repo

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Adapters.Posts
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
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

    {:ok, liker} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "liker@example.com", "password" => "supersecret", "name" => "Liker"}
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: liker, remember_me: false})

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

    %{post: post, access_token: access_token, liker: liker}
  end

  describe "POST /api/posts/:post_id/likes" do
    test "likes the post when authenticated", %{
      conn: conn,
      post: post,
      access_token: token,
      liker: liker
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post.id}/likes")

      assert json_response(conn, 200) == %{"data" => %{"liked" => true, "like_count" => 1}}

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{
          action: "record_action",
          actor_id: liker.id,
          action_type: "REACT",
          resource_type: "post",
          resource_id: post.id,
          community_id: "default"
        }
      )
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
    test "unlikes a liked post", %{conn: conn, post: post, access_token: token, liker: liker} do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")
      post(conn, ~p"/api/posts/#{post.id}/likes")

      conn2 = delete(conn, ~p"/api/posts/#{post.id}/likes")
      assert json_response(conn2, 200) == %{"data" => %{"liked" => false, "like_count" => 0}}

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{
          action: "record_action",
          actor_id: liker.id,
          action_type: "UNREACT",
          resource_type: "post",
          resource_id: post.id,
          community_id: "default"
        }
      )
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post} do
      conn = delete(conn, ~p"/api/posts/#{post.id}/likes")
      assert json_response(conn, 401)
    end
  end
end
