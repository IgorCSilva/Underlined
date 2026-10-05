defmodule ApiWeb.BookControllerTest do
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

  defp create_post(user, book, attrs) do
    {:ok, post} =
      Posts.create_post(%CreatePostUsecaseDto{
        user: user,
        attrs:
          Map.merge(
            %{"book_id" => book.id, "passage_text" => "A short passage.", "thinking" => "Thinking."},
            attrs
          )
      })

    post
  end

  describe "GET /api/books" do
    test "returns an empty list when there are no books", %{conn: conn} do
      conn = get(conn, ~p"/api/books")
      assert json_response(conn, 200) == %{"data" => []}
    end

    test "returns all books when there is no query", %{conn: conn} do
      {:ok, _book} =
        Catalog.add_book(%AddBookUsecaseDto{
          attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
        })

      conn = get(conn, ~p"/api/books")
      assert %{"data" => [%{"title" => "Sapiens"}]} = json_response(conn, 200)
    end

    test "filters by the search query", %{conn: conn} do
      {:ok, book} =
        Catalog.add_book(%AddBookUsecaseDto{
          attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
        })

      {:ok, _other} =
        Catalog.add_book(%AddBookUsecaseDto{
          attrs: %{"title" => "Atomic Habits", "author" => "James Clear"}
        })

      conn = get(conn, ~p"/api/books?q=sapiens")
      assert %{"data" => [%{"id" => id}]} = json_response(conn, 200)
      assert id == book.id
    end
  end

  describe "GET /api/books/:id" do
    test "returns a book", %{conn: conn} do
      {:ok, book} =
        Catalog.add_book(%AddBookUsecaseDto{
          attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
        })

      conn = get(conn, ~p"/api/books/#{book.id}")

      assert %{"data" => %{"id" => id, "title" => "Sapiens", "author" => "Yuval Noah Harari"}} =
               json_response(conn, 200)

      assert id == book.id
    end

    test "returns 404 for an unknown book", %{conn: conn} do
      conn = get(conn, ~p"/api/books/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end

  describe "POST /api/books" do
    test "creates a book when authenticated", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books", book: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"})

      assert %{"data" => %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}} =
               json_response(conn, 200)
    end

    test "rejects an unauthenticated request", %{conn: conn} do
      conn =
        post(conn, ~p"/api/books", book: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"})

      assert json_response(conn, 401)
    end

    test "returns validation errors", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books", book: %{"title" => ""})

      assert json_response(conn, 422)
    end

    test "returns the existing book instead of creating a duplicate", %{
      conn: conn,
      access_token: token
    } do
      {:ok, existing} =
        Catalog.add_book(%AddBookUsecaseDto{
          attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
        })

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books", book: %{"title" => "sapiens", "author" => "yuval noah harari"})

      assert %{"data" => %{"id" => id}} = json_response(conn, 200)
      assert id == existing.id
    end
  end

  describe "GET /api/books/:id/page" do
    setup %{user: author} do
      {:ok, reader} =
        Accounts.register_user(%RegisterUserUsecaseDto{
          attrs: %{"email" => "other@example.com", "password" => "supersecret", "name" => "Other Reader"}
        })

      {:ok, book} =
        Catalog.add_book(%AddBookUsecaseDto{
          attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
        })

      %{author: author, reader: reader, book: book}
    end

    test "returns the book's stats and matching posts, newest first", %{
      conn: conn,
      author: author,
      book: book
    } do
      _older = create_post(author, book, %{"thinking" => "Older."})
      newer = create_post(author, book, %{"thinking" => "Newer."})

      conn = get(conn, ~p"/api/books/#{book.id}/page")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == book.id
      assert data["title"] == "Sapiens"
      assert data["stats"] == %{"post_count" => 2, "reader_count" => 1}
      assert Enum.map(data["posts"], & &1["thinking"]) == [newer.thinking, "Older."]
    end

    test "counts distinct readers, not posts", %{
      conn: conn,
      author: author,
      reader: reader,
      book: book
    } do
      create_post(author, book, %{"thinking" => "First."})
      create_post(author, book, %{"thinking" => "Second, same author."})
      create_post(reader, book, %{"thinking" => "Third, different reader."})

      conn = get(conn, ~p"/api/books/#{book.id}/page")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["stats"] == %{"post_count" => 3, "reader_count" => 2}
    end

    test "paginates with the before cursor, same convention as the main feed", %{
      conn: conn,
      author: author,
      book: book
    } do
      create_post(author, book, %{"thinking" => "Oldest."})
      middle = create_post(author, book, %{"thinking" => "Middle."})
      _newest = create_post(author, book, %{"thinking" => "Newest."})

      conn = get(conn, ~p"/api/books/#{book.id}/page", before: DateTime.to_iso8601(middle.inserted_at))

      assert %{"data" => data} = json_response(conn, 200)
      assert Enum.map(data["posts"], & &1["thinking"]) == ["Oldest."]
    end

    test "annotates liked_by_user/bookmarked_by_user for an authenticated caller", %{
      conn: conn,
      author: author,
      access_token: token,
      book: book
    } do
      post = create_post(author, book, %{})

      conn_auth = put_req_header(conn, "authorization", "Bearer #{token}")
      like_conn = post(conn_auth, ~p"/api/posts/#{post.id}/likes")
      assert json_response(like_conn, 200)

      conn2 = get(conn_auth, ~p"/api/books/#{book.id}/page")
      assert %{"data" => %{"posts" => [post_data]}} = json_response(conn2, 200)
      assert post_data["liked_by_user"] == true
      assert post_data["bookmarked_by_user"] == false
    end

    test "works for an unauthenticated caller, with liked/bookmarked false", %{
      conn: conn,
      author: author,
      book: book
    } do
      create_post(author, book, %{})

      conn = get(conn, ~p"/api/books/#{book.id}/page")

      assert %{"data" => %{"posts" => [post_data]}} = json_response(conn, 200)
      assert post_data["liked_by_user"] == false
      assert post_data["bookmarked_by_user"] == false
    end

    test "returns 404 for an unknown book", %{conn: conn} do
      conn = get(conn, ~p"/api/books/#{Ecto.UUID.generate()}/page")
      assert json_response(conn, 404)
    end
  end
end
