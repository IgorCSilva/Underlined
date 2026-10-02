defmodule ApiWeb.CommentControllerTest do
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

    {:ok, commenter} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{
          "email" => "commenter@example.com",
          "password" => "supersecret",
          "name" => "Commenter"
        }
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: commenter, remember_me: false})

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

    %{post: post, author: author, commenter: commenter, access_token: access_token}
  end

  describe "POST /api/posts/:post_id/comments" do
    test "creates a top-level comment when authenticated", %{
      conn: conn,
      post: post,
      access_token: token
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["type"] == "comment"
      assert data["body"] == "Great read!"
      assert data["parent_comment_id"] == nil
      assert data["replies"] == []
    end

    test "creates a reply when given a parent_comment_id", %{
      conn: conn,
      post: post,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      parent_conn =
        post(conn, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => parent_id}} = json_response(parent_conn, 201)

      reply_conn =
        post(conn, ~p"/api/posts/#{post.id}/comments",
          comment: %{"body" => "Agreed!", "parent_comment_id" => parent_id}
        )

      assert %{"data" => data} = json_response(reply_conn, 201)
      assert data["type"] == "reply"
      assert data["parent_comment_id"] == parent_id
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post} do
      conn = post(conn, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})
      assert json_response(conn, 401)
    end

    test "returns 422 for a blank body", %{conn: conn, post: post, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post.id}/comments", comment: %{"body" => ""})

      assert json_response(conn, 422)
    end

    test "returns 422 when replying to a reply", %{conn: conn, post: post, access_token: token} do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      parent_conn =
        post(conn, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => parent_id}} = json_response(parent_conn, 201)

      reply_conn =
        post(conn, ~p"/api/posts/#{post.id}/comments",
          comment: %{"body" => "Agreed!", "parent_comment_id" => parent_id}
        )

      %{"data" => %{"id" => reply_id}} = json_response(reply_conn, 201)

      conn2 =
        post(conn, ~p"/api/posts/#{post.id}/comments",
          comment: %{"body" => "Me too!", "parent_comment_id" => reply_id}
        )

      assert json_response(conn2, 422)
    end

    test "returns 404 for an unknown post", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{Ecto.UUID.generate()}/comments", comment: %{"body" => "Hi"})

      assert json_response(conn, 404)
    end

    test "returns 429 after exceeding the rate limit", %{
      conn: conn,
      post: post,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      for n <- 1..5 do
        resp =
          post(conn, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Comment #{n}"})

        assert json_response(resp, 201)
      end

      conn2 = post(conn, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "One too many"})
      assert json_response(conn2, 429)
    end
  end

  describe "PUT /api/posts/:post_id/comments/:id" do
    test "lets the author edit the comment body", %{conn: conn, post: post, access_token: token} do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      create_conn =
        post(authed, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => comment_id}} = json_response(create_conn, 201)

      update_conn =
        put(authed, ~p"/api/posts/#{post.id}/comments/#{comment_id}",
          comment: %{"body" => "Even better read!"}
        )

      assert %{"data" => data} = json_response(update_conn, 200)
      assert data["id"] == comment_id
      assert data["body"] == "Even better read!"
    end

    test "lets the author edit a parent comment that already has replies", %{
      conn: conn,
      post: post,
      access_token: token
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      create_conn =
        post(authed, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => comment_id}} = json_response(create_conn, 201)

      post(authed, ~p"/api/posts/#{post.id}/comments",
        comment: %{"body" => "Agreed!", "parent_comment_id" => comment_id}
      )

      update_conn =
        put(authed, ~p"/api/posts/#{post.id}/comments/#{comment_id}",
          comment: %{"body" => "Even better read!"}
        )

      assert %{"data" => data} = json_response(update_conn, 200)
      assert data["body"] == "Even better read!"
      assert [reply] = data["replies"]
      assert reply["body"] == "Agreed!"
    end

    test "rejects an edit from a user who didn't write the comment", %{
      conn: conn,
      post: post,
      access_token: token,
      author: author
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      create_conn =
        post(authed, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => comment_id}} = json_response(create_conn, 201)

      {:ok, author_token, _refresh_token} =
        Accounts.create_session(%CreateSessionUsecaseDto{user: author, remember_me: false})

      other_conn =
        conn
        |> put_req_header("authorization", "Bearer #{author_token}")
        |> put(~p"/api/posts/#{post.id}/comments/#{comment_id}",
          comment: %{"body" => "Hijacked!"}
        )

      assert json_response(other_conn, 403)
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post, access_token: token} do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      create_conn =
        post(authed, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => comment_id}} = json_response(create_conn, 201)

      conn =
        put(conn, ~p"/api/posts/#{post.id}/comments/#{comment_id}", comment: %{"body" => "Nope"})

      assert json_response(conn, 401)
    end

    test "returns 404 for an unknown comment", %{conn: conn, post: post, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/posts/#{post.id}/comments/#{Ecto.UUID.generate()}",
          comment: %{"body" => "Nope"}
        )

      assert json_response(conn, 404)
    end

    test "returns 422 for a blank body", %{conn: conn, post: post, access_token: token} do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      create_conn =
        post(authed, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => comment_id}} = json_response(create_conn, 201)

      update_conn =
        put(authed, ~p"/api/posts/#{post.id}/comments/#{comment_id}", comment: %{"body" => ""})

      assert json_response(update_conn, 422)
    end
  end

  describe "GET /api/posts/:post_id/comments" do
    test "lists top-level comments with nested replies", %{
      conn: conn,
      post: post,
      access_token: token
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      parent_conn =
        post(authed, ~p"/api/posts/#{post.id}/comments", comment: %{"body" => "Great read!"})

      %{"data" => %{"id" => parent_id}} = json_response(parent_conn, 201)

      post(authed, ~p"/api/posts/#{post.id}/comments",
        comment: %{"body" => "Agreed!", "parent_comment_id" => parent_id}
      )

      conn2 = get(conn, ~p"/api/posts/#{post.id}/comments")
      assert %{"data" => [comment]} = json_response(conn2, 200)
      assert comment["id"] == parent_id
      assert [reply] = comment["replies"]
      assert reply["body"] == "Agreed!"
    end

    test "returns an empty list for a post with no comments", %{conn: conn, post: post} do
      conn = get(conn, ~p"/api/posts/#{post.id}/comments")
      assert json_response(conn, 200) == %{"data" => []}
    end
  end
end
