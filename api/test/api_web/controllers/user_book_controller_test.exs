defmodule ApiWeb.UserBookControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  setup :verify_on_exit!

  setup %{conn: conn} do
    Api.MailerMock
    |> stub(:deliver_confirmation_instructions, fn _user, _url -> {:ok, :delivered} end)

    {:ok, reader} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "reader@example.com", "password" => "supersecret", "name" => "Reader"}
      })

    {:ok, other_reader} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{
          "email" => "other_reader@example.com",
          "password" => "supersecret",
          "name" => "Other Reader"
        }
      })

    {:ok, token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: reader, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    %{conn: conn, reader: reader, other_reader: other_reader, token: token, book: book}
  end

  defp auth(conn, token), do: put_req_header(conn, "authorization", "Bearer #{token}")

  describe "PUT /api/books/:book_id/shelf" do
    test "shelves a book under a reading status", %{conn: conn, token: token, book: book} do
      conn =
        conn
        |> auth(token)
        |> put(~p"/api/books/#{book.id}/shelf", %{"shelf" => %{"status" => "to_read"}})

      assert %{"data" => %{"status" => "to_read", "book" => %{"id" => book_id}}} =
               json_response(conn, 200)

      assert book_id == book.id
    end

    test "moves an already-shelved book to a different status", %{
      conn: conn,
      token: token,
      book: book
    } do
      conn
      |> auth(token)
      |> put(~p"/api/books/#{book.id}/shelf", %{"shelf" => %{"status" => "to_read"}})

      conn =
        conn
        |> auth(token)
        |> put(~p"/api/books/#{book.id}/shelf", %{"shelf" => %{"status" => "reading"}})

      assert %{"data" => %{"status" => "reading"}} = json_response(conn, 200)
    end

    test "rejects an unknown status", %{conn: conn, token: token, book: book} do
      conn =
        conn
        |> auth(token)
        |> put(~p"/api/books/#{book.id}/shelf", %{"shelf" => %{"status" => "finished"}})

      assert json_response(conn, 422)
    end

    test "rejects a book that doesn't exist", %{conn: conn, token: token} do
      conn =
        conn
        |> auth(token)
        |> put(~p"/api/books/#{Ecto.UUID.generate()}/shelf", %{
          "shelf" => %{"status" => "to_read"}
        })

      assert json_response(conn, 404)
    end

    test "rejects an unauthenticated request", %{conn: conn, book: book} do
      conn =
        put(conn, ~p"/api/books/#{book.id}/shelf", %{"shelf" => %{"status" => "to_read"}})

      assert json_response(conn, 401)
    end
  end

  describe "GET /api/users/:id/bookcase" do
    test "is empty when the user hasn't shelved anything", %{
      conn: conn,
      reader: reader
    } do
      conn = get(conn, ~p"/api/users/#{reader.id}/bookcase")
      assert %{"data" => []} = json_response(conn, 200)
    end

    test "lists every book the user has shelved, with its status", %{
      conn: conn,
      token: token,
      reader: reader,
      book: book
    } do
      conn
      |> auth(token)
      |> put(~p"/api/books/#{book.id}/shelf", %{"shelf" => %{"status" => "read"}})

      show_conn = build_conn() |> get(~p"/api/users/#{reader.id}/bookcase")

      assert %{"data" => [%{"status" => "read", "book" => %{"id" => book_id}}]} =
               json_response(show_conn, 200)

      assert book_id == book.id
    end

    test "is viewable by any visitor, not just the owner (read-only)", %{
      conn: conn,
      token: token,
      book: book,
      other_reader: other_reader
    } do
      conn
      |> auth(token)
      |> put(~p"/api/books/#{book.id}/shelf", %{"shelf" => %{"status" => "reading"}})

      conn = get(build_conn(), ~p"/api/users/#{other_reader.id}/bookcase")
      assert %{"data" => []} = json_response(conn, 200)
    end

    test "404s for a user that doesn't exist", %{conn: conn} do
      conn = get(conn, ~p"/api/users/#{Ecto.UUID.generate()}/bookcase")
      assert json_response(conn, 404)
    end
  end
end
