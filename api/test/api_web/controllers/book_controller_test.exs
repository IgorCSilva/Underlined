defmodule ApiWeb.BookControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
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
end
