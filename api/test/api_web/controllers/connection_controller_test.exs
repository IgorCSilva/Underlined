defmodule ApiWeb.ConnectionControllerTest do
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

    {:ok, user} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "reader@example.com", "password" => "supersecret", "name" => "Reader"}
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: user, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    {:ok, post_a} = create_post(user, book, "Passage A.", "Thinking A.")
    {:ok, post_b} = create_post(user, book, "Passage B.", "Thinking B.")

    %{user: user, access_token: access_token, book: book, post_a: post_a, post_b: post_b}
  end

  defp create_post(user, book, passage_text, thinking) do
    Posts.create_post(%CreatePostUsecaseDto{
      user: user,
      attrs: %{"book_id" => book.id, "passage_text" => passage_text, "thinking" => thinking}
    })
  end

  describe "POST /api/posts/:post_id/connections" do
    test "connects two posts when authenticated", %{
      conn: conn,
      access_token: token,
      post_a: post_a,
      post_b: post_b
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post_a.id}/connections",
          connection: %{"related_post_id" => post_b.id, "relationship_type" => "expands_on"}
        )

      assert %{
               "data" => %{
                 "relationship_type" => "expands_on",
                 "connected_post" => %{"id" => connected_id}
               }
             } = json_response(conn, 201)

      assert connected_id == post_b.id
    end

    test "connecting the same pair with the same type twice is idempotent", %{
      conn: conn,
      access_token: token,
      post_a: post_a,
      post_b: post_b
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      first =
        post(conn, ~p"/api/posts/#{post_a.id}/connections",
          connection: %{"related_post_id" => post_b.id, "relationship_type" => "similar_idea"}
        )

      second =
        post(conn, ~p"/api/posts/#{post_a.id}/connections",
          connection: %{"related_post_id" => post_b.id, "relationship_type" => "similar_idea"}
        )

      assert %{"data" => %{"id" => id1}} = json_response(first, 201)
      assert %{"data" => %{"id" => id2}} = json_response(second, 201)
      assert id1 == id2
    end

    test "rejects connecting a post to itself", %{conn: conn, access_token: token, post_a: post_a} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post_a.id}/connections",
          connection: %{"related_post_id" => post_a.id, "relationship_type" => "similar_idea"}
        )

      assert %{"errors" => %{"code" => "cannot_connect_self"}} = json_response(conn, 422)
    end

    test "rejects an unknown relationship_type", %{
      conn: conn,
      access_token: token,
      post_a: post_a,
      post_b: post_b
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post_a.id}/connections",
          connection: %{"related_post_id" => post_b.id, "relationship_type" => "bogus"}
        )

      assert json_response(conn, 422)
    end

    test "returns 404 when the related post doesn't exist", %{
      conn: conn,
      access_token: token,
      post_a: post_a
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{post_a.id}/connections",
          connection: %{
            "related_post_id" => Ecto.UUID.generate(),
            "relationship_type" => "expands_on"
          }
        )

      assert json_response(conn, 404)
    end

    test "returns 404 when the post itself doesn't exist", %{
      conn: conn,
      access_token: token,
      post_b: post_b
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{Ecto.UUID.generate()}/connections",
          connection: %{"related_post_id" => post_b.id, "relationship_type" => "expands_on"}
        )

      assert json_response(conn, 404)
    end

    test "rejects an unauthenticated request", %{conn: conn, post_a: post_a, post_b: post_b} do
      conn =
        post(conn, ~p"/api/posts/#{post_a.id}/connections",
          connection: %{"related_post_id" => post_b.id, "relationship_type" => "expands_on"}
        )

      assert json_response(conn, 401)
    end
  end

  describe "GET /api/posts/:id/connections" do
    test "returns an empty list for a post with no connections", %{conn: conn, post_a: post_a} do
      conn = get(conn, ~p"/api/posts/#{post_a.id}/connections")
      assert json_response(conn, 200) == %{"data" => []}
    end

    test "shows a connection on both posts it links, each pointing at the other", %{
      conn: conn,
      access_token: token,
      post_a: post_a,
      post_b: post_b
    } do
      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/posts/#{post_a.id}/connections",
        connection: %{"related_post_id" => post_b.id, "relationship_type" => "contradicts"}
      )

      from_a = get(conn, ~p"/api/posts/#{post_a.id}/connections")

      assert %{
               "data" => [
                 %{"relationship_type" => "contradicts", "connected_post" => %{"id" => from_a_connected}}
               ]
             } = json_response(from_a, 200)

      assert from_a_connected == post_b.id

      from_b = get(build_conn(), ~p"/api/posts/#{post_b.id}/connections")

      assert %{
               "data" => [
                 %{"relationship_type" => "contradicts", "connected_post" => %{"id" => from_b_connected}}
               ]
             } = json_response(from_b, 200)

      assert from_b_connected == post_a.id
    end

    test "returns 404 for an unknown post", %{conn: conn} do
      conn = get(conn, ~p"/api/posts/#{Ecto.UUID.generate()}/connections")
      assert json_response(conn, 404)
    end
  end
end
