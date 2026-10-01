defmodule ApiWeb.PostControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Accounts
  alias Api.Catalog

  setup :verify_on_exit!

  setup do
    Api.MailerMock |> stub(:deliver_confirmation_instructions, fn _user, _url -> {:ok, :delivered} end)

    {:ok, user} =
      Accounts.register_user(%{
        "email" => "reader@example.com",
        "password" => "supersecret",
        "name" => "Reader One"
      })

    {:ok, access_token, _refresh_token} = Accounts.create_session(user, false)
    {:ok, book} = Catalog.add_book(%{"title" => "Sapiens", "author" => "Yuval Noah Harari"})

    %{user: user, access_token: access_token, book: book}
  end

  @valid_post_params %{
    "passage_text" => "A short passage.",
    "thinking" => "This changed how I think.",
    "keywords" => ["attention", "nature-writing"]
  }

  describe "POST /api/posts" do
    test "creates a post when authenticated", %{conn: conn, access_token: token, book: book} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: Map.put(@valid_post_params, "book_id", book.id))

      assert %{
               "data" => %{
                 "thinking" => "This changed how I think.",
                 "book" => %{"id" => book_id},
                 "passage" => %{"text" => "A short passage."},
                 "keywords" => keywords
               }
             } = json_response(conn, 201)

      assert book_id == book.id
      assert Enum.sort(keywords) == ["attention", "nature-writing"]
    end

    test "rejects an unauthenticated request", %{conn: conn, book: book} do
      conn = post(conn, ~p"/api/posts", post: Map.put(@valid_post_params, "book_id", book.id))
      assert json_response(conn, 401)
    end

    test "returns validation errors", %{conn: conn, access_token: token, book: book} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: @valid_post_params |> Map.put("book_id", book.id) |> Map.put("thinking", ""))

      assert json_response(conn, 422)
    end

    test "returns 404 when the book doesn't exist", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: Map.put(@valid_post_params, "book_id", Ecto.UUID.generate()))

      assert json_response(conn, 404)
    end
  end

  describe "GET /api/posts" do
    test "lists posts newest first without authentication", %{conn: conn, access_token: token, book: book} do
      conn1 =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: @valid_post_params |> Map.put("book_id", book.id) |> Map.put("passage_text", "First."))

      %{"data" => %{"id" => first_id}} = json_response(conn1, 201)

      conn2 =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: @valid_post_params |> Map.put("book_id", book.id) |> Map.put("passage_text", "Second."))

      %{"data" => %{"id" => second_id}} = json_response(conn2, 201)

      conn = get(build_conn(), ~p"/api/posts")
      assert %{"data" => [%{"id" => ^second_id}, %{"id" => ^first_id}]} = json_response(conn, 200)
    end

    test "returns an empty list when there are no posts", %{conn: conn} do
      conn = get(conn, ~p"/api/posts")
      assert json_response(conn, 200) == %{"data" => []}
    end
  end

  describe "GET /api/posts/:id" do
    test "returns a post", %{conn: conn, access_token: token, book: book} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: Map.put(@valid_post_params, "book_id", book.id))

      assert %{"data" => %{"id" => id}} = json_response(conn, 201)

      conn = get(build_conn(), ~p"/api/posts/#{id}")

      assert %{
               "data" => %{
                 "id" => ^id,
                 "thinking" => "This changed how I think.",
                 "like_count" => 0,
                 "liked_by_user" => false
               }
             } = json_response(conn, 200)
    end

    test "returns 404 for an unknown post", %{conn: conn} do
      conn = get(conn, ~p"/api/posts/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end

    test "reports liked_by_user true for a user who liked the post, without requiring auth for others",
         %{conn: conn, access_token: token, book: book} do
      conn1 =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: Map.put(@valid_post_params, "book_id", book.id))

      %{"data" => %{"id" => id}} = json_response(conn1, 201)

      like_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts/#{id}/likes")

      assert json_response(like_conn, 200)

      authed_show =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/posts/#{id}")

      assert %{"data" => %{"like_count" => 1, "liked_by_user" => true}} = json_response(authed_show, 200)

      anon_show = get(build_conn(), ~p"/api/posts/#{id}")
      assert %{"data" => %{"like_count" => 1, "liked_by_user" => false}} = json_response(anon_show, 200)
    end
  end
end
