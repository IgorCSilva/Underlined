defmodule ApiWeb.ClubReadingProgressControllerTest do
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

    {:ok, creator} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{
          "email" => "creator@example.com",
          "password" => "supersecret",
          "name" => "Creator"
        }
      })

    {:ok, creator_token, _} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: creator, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    create_response =
      conn
      |> put_req_header("authorization", "Bearer #{creator_token}")
      |> post(~p"/api/books/#{book.id}/clubs", %{"club" => %{"name" => "Sapiens Readers"}})

    %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

    chapter_response =
      conn
      |> auth(creator_token)
      |> post(~p"/api/clubs/#{club_id}/chapters", %{"chapter" => %{"label" => "Chapter 1"}})

    %{"data" => %{"id" => chapter_1_id}} = json_response(chapter_response, 201)

    %{creator_token: creator_token, book: book, club_id: club_id, chapter_1_id: chapter_1_id}
  end

  defp auth(conn, token), do: put_req_header(conn, "authorization", "Bearer #{token}")

  describe "GET /api/clubs/:club_id/reading_progress" do
    test "defaults to no chapter when the reader hasn't set any progress", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      conn = conn |> auth(token) |> get(~p"/api/clubs/#{club_id}/reading_progress")
      assert %{"data" => %{"chapter" => nil}} = json_response(conn, 200)
    end

    test "rejects an unauthenticated request", %{conn: conn, club_id: club_id} do
      conn = get(conn, ~p"/api/clubs/#{club_id}/reading_progress")
      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/clubs/:club_id/reading_progress" do
    test "sets the caller's furthest-read chapter", %{
      conn: conn,
      creator_token: token,
      club_id: club_id,
      chapter_1_id: chapter_1_id
    } do
      conn =
        conn
        |> auth(token)
        |> put(~p"/api/clubs/#{club_id}/reading_progress", %{
          "reading_progress" => %{"chapter_id" => chapter_1_id}
        })

      assert %{"data" => %{"chapter" => %{"id" => ^chapter_1_id, "position" => 1}}} =
               json_response(conn, 200)

      show_conn = build_conn() |> auth(token) |> get(~p"/api/clubs/#{club_id}/reading_progress")

      assert %{"data" => %{"chapter" => %{"id" => ^chapter_1_id}}} = json_response(show_conn, 200)
    end

    test "can reset progress back to not-started with a nil chapter_id", %{
      conn: conn,
      creator_token: token,
      club_id: club_id,
      chapter_1_id: chapter_1_id
    } do
      conn
      |> auth(token)
      |> put(~p"/api/clubs/#{club_id}/reading_progress", %{
        "reading_progress" => %{"chapter_id" => chapter_1_id}
      })

      conn =
        conn
        |> auth(token)
        |> put(~p"/api/clubs/#{club_id}/reading_progress", %{
          "reading_progress" => %{"chapter_id" => nil}
        })

      assert %{"data" => %{"chapter" => nil}} = json_response(conn, 200)
    end

    test "rejects a chapter that doesn't belong to this club", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      conn =
        conn
        |> auth(token)
        |> put(~p"/api/clubs/#{club_id}/reading_progress", %{
          "reading_progress" => %{"chapter_id" => Ecto.UUID.generate()}
        })

      assert json_response(conn, 422)
    end

    test "rejects an unauthenticated request", %{conn: conn, club_id: club_id} do
      conn =
        put(conn, ~p"/api/clubs/#{club_id}/reading_progress", %{
          "reading_progress" => %{"chapter_id" => nil}
        })

      assert json_response(conn, 401)
    end
  end
end
