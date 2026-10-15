defmodule ApiWeb.ConnectionCommentControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Adapters.Posts
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
  alias Api.Usecases.Connection.ConnectPosts.ConnectPostsUsecaseDto
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

    {:ok, post_a} =
      Posts.create_post(%CreatePostUsecaseDto{
        user: author,
        attrs: %{"book_id" => book.id, "passage_text" => "Passage A.", "thinking" => "Thinking A."}
      })

    {:ok, post_b} =
      Posts.create_post(%CreatePostUsecaseDto{
        user: author,
        attrs: %{"book_id" => book.id, "passage_text" => "Passage B.", "thinking" => "Thinking B."}
      })

    {:ok, connection} =
      Posts.connect_posts(%ConnectPostsUsecaseDto{
        user: author,
        post_id: post_a.id,
        related_post_id: post_b.id,
        relationship_type: "contradicts"
      })

    %{
      connection: connection,
      post_a: post_a,
      author: author,
      commenter: commenter,
      access_token: access_token
    }
  end

  describe "POST /api/connections/:connection_id/comments" do
    test "creates a top-level comment when authenticated", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "I disagree!"})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["type"] == "comment"
      assert data["body"] == "I disagree!"
      assert data["parent_comment_id"] == nil
      assert data["replies"] == []
    end

    test "creates a reply when given a parent_comment_id", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      parent_conn =
        post(conn, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "I disagree!"})

      %{"data" => %{"id" => parent_id}} = json_response(parent_conn, 201)

      reply_conn =
        post(conn, ~p"/api/connections/#{connection.id}/comments",
          comment: %{"body" => "Me too!", "parent_comment_id" => parent_id}
        )

      assert %{"data" => data} = json_response(reply_conn, 201)
      assert data["type"] == "reply"
      assert data["parent_comment_id"] == parent_id
    end

    test "persists the given side", %{conn: conn, connection: connection, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/connections/#{connection.id}/comments",
          comment: %{"body" => "I agree with the first post", "side" => "post_a"}
        )

      assert %{"data" => data} = json_response(conn, 201)
      assert data["side"] == "post_a"
    end

    test "defaults side to neutral when omitted", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "No side taken"})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["side"] == "neutral"
    end

    test "rejects an invalid side", %{conn: conn, connection: connection, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/connections/#{connection.id}/comments",
          comment: %{"body" => "Hi", "side" => "bogus"}
        )

      assert json_response(conn, 422)
    end

    test "a reply may take a different side than its parent", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      parent_conn =
        post(conn, ~p"/api/connections/#{connection.id}/comments",
          comment: %{"body" => "I disagree!", "side" => "post_a"}
        )

      %{"data" => %{"id" => parent_id}} = json_response(parent_conn, 201)

      reply_conn =
        post(conn, ~p"/api/connections/#{connection.id}/comments",
          comment: %{
            "body" => "Actually I think the other side has a point",
            "parent_comment_id" => parent_id,
            "side" => "post_b"
          }
        )

      assert %{"data" => data} = json_response(reply_conn, 201)
      assert data["side"] == "post_b"
    end

    test "rejects an unauthenticated request", %{conn: conn, connection: connection} do
      conn =
        post(conn, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "Hi"})

      assert json_response(conn, 401)
    end

    test "returns 422 for a blank body", %{conn: conn, connection: connection, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/connections/#{connection.id}/comments", comment: %{"body" => ""})

      assert json_response(conn, 422)
    end

    test "returns 422 when replying to a reply", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      parent_conn =
        post(conn, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "I disagree!"})

      %{"data" => %{"id" => parent_id}} = json_response(parent_conn, 201)

      reply_conn =
        post(conn, ~p"/api/connections/#{connection.id}/comments",
          comment: %{"body" => "Me too!", "parent_comment_id" => parent_id}
        )

      %{"data" => %{"id" => reply_id}} = json_response(reply_conn, 201)

      conn2 =
        post(conn, ~p"/api/connections/#{connection.id}/comments",
          comment: %{"body" => "And me!", "parent_comment_id" => reply_id}
        )

      assert %{"errors" => %{"code" => "invalid_parent"}} = json_response(conn2, 422)
    end

    test "returns 404 for an unknown connection", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/connections/#{Ecto.UUID.generate()}/comments", comment: %{"body" => "Hi"})

      assert json_response(conn, 404)
    end

    test "returns 429 after exceeding the rate limit", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      for n <- 1..5 do
        resp =
          post(conn, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "Comment #{n}"})

        assert json_response(resp, 201)
      end

      conn2 =
        post(conn, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "One too many"})

      assert json_response(conn2, 429)
    end
  end

  describe "GET /api/connections/:connection_id/comments" do
    test "returns an empty list when the debate has no comments yet", %{
      conn: conn,
      connection: connection
    } do
      conn = get(conn, ~p"/api/connections/#{connection.id}/comments")
      assert json_response(conn, 200) == %{"data" => []}
    end

    test "lists top-level comments, oldest first, with replies nested", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      post(authed, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "First"})
      post(authed, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "Second"})

      conn = get(conn, ~p"/api/connections/#{connection.id}/comments")

      assert %{"data" => [%{"body" => "First"}, %{"body" => "Second"}]} = json_response(conn, 200)
    end

    test "does not show a post's own comment thread", %{
      conn: conn,
      connection: connection,
      post_a: post_a,
      author: author
    } do
      Posts.create_comment(%Api.Usecases.Comment.CreateComment.CreateCommentUsecaseDto{
        user: author,
        post_id: post_a.id,
        attrs: %{"body" => "A regular post comment"}
      })

      conn = get(conn, ~p"/api/connections/#{connection.id}/comments")
      assert json_response(conn, 200) == %{"data" => []}
    end
  end

  describe "PUT /api/connections/:connection_id/comments/:id" do
    test "lets the author edit their own comment", %{
      conn: conn,
      connection: connection,
      access_token: token
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      create_conn =
        post(authed, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "Original"})

      %{"data" => %{"id" => comment_id}} = json_response(create_conn, 201)

      update_conn =
        put(authed, ~p"/api/connections/#{connection.id}/comments/#{comment_id}",
          comment: %{"body" => "Edited"}
        )

      assert %{"data" => %{"body" => "Edited"}} = json_response(update_conn, 200)
    end

    test "forbids editing someone else's comment", %{
      conn: conn,
      connection: connection,
      access_token: token,
      author: author
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{token}")

      create_conn =
        post(authed, ~p"/api/connections/#{connection.id}/comments", comment: %{"body" => "Original"})

      %{"data" => %{"id" => comment_id}} = json_response(create_conn, 201)

      {:ok, author_token, _} =
        Accounts.create_session(%Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto{
          user: author,
          remember_me: false
        })

      other_conn =
        conn
        |> put_req_header("authorization", "Bearer #{author_token}")
        |> put(~p"/api/connections/#{connection.id}/comments/#{comment_id}",
          comment: %{"body" => "Hijacked"}
        )

      assert json_response(other_conn, 403)
    end
  end
end
