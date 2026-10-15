defmodule ApiWeb.ClubControllerTest do
  use ApiWeb.ConnCase, async: true
  use Oban.Testing, repo: Api.Repo

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
  alias Api.Usecases.Session.CreateSession.CreateSessionUsecaseDto
  alias Api.Usecases.User.RegisterUser.RegisterUserUsecaseDto

  setup :verify_on_exit!

  setup do
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

    {:ok, other} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "other@example.com", "password" => "supersecret", "name" => "Other"}
      })

    {:ok, creator_token, _} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: creator, remember_me: false})

    {:ok, other_token, _} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: other, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    %{
      creator: creator,
      other: other,
      creator_token: creator_token,
      other_token: other_token,
      book: book
    }
  end

  defp create_club(conn, token, book, attrs \\ %{"name" => "Sapiens Readers"}) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> post(~p"/api/books/#{book.id}/clubs", %{"club" => attrs})
  end

  describe "POST /api/books/:book_id/clubs" do
    test "creates a club with the creator as its first member", %{
      conn: conn,
      creator: creator,
      creator_token: token,
      book: book
    } do
      conn =
        create_club(conn, token, book, %{
          "name" => "Sapiens Readers",
          "description" => "Chapter by chapter"
        })

      assert %{
               "data" => %{
                 "name" => "Sapiens Readers",
                 "description" => "Chapter by chapter",
                 "member_count" => 1,
                 "joined_by_user" => true,
                 "book" => %{"id" => book_id},
                 "creator" => %{"id" => creator_id}
               }
             } = json_response(conn, 201)

      assert book_id == book.id
      assert creator_id == creator.id

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{action: "ensure_member", actor_id: creator.id}
      )
    end

    test "rejects an unauthenticated request", %{conn: conn, book: book} do
      conn =
        post(conn, ~p"/api/books/#{book.id}/clubs", %{"club" => %{"name" => "Sapiens Readers"}})

      assert json_response(conn, 401)
    end

    test "returns 422 when the name is missing", %{conn: conn, creator_token: token, book: book} do
      conn = create_club(conn, token, book, %{"name" => ""})
      assert json_response(conn, 422)
    end

    test "returns 404 when the book doesn't exist", %{conn: conn, creator_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books/#{Ecto.UUID.generate()}/clubs", %{"club" => %{"name" => "Readers"}})

      assert json_response(conn, 404)
    end
  end

  describe "GET /api/books/:book_id/clubs" do
    test "lists clubs scoped to the book, annotated for the viewer", %{
      conn: conn,
      creator_token: creator_token,
      other_token: other_token,
      book: book
    } do
      create_club(conn, creator_token, book)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{other_token}")
        |> get(~p"/api/books/#{book.id}/clubs")

      assert %{"data" => [%{"name" => "Sapiens Readers", "joined_by_user" => false}]} =
               json_response(conn, 200)
    end

    test "returns an empty list when the book has no clubs", %{conn: conn, book: book} do
      conn = get(conn, ~p"/api/books/#{book.id}/clubs")
      assert json_response(conn, 200) == %{"data" => []}
    end
  end

  describe "GET /api/clubs/:id" do
    test "returns the club annotated for the viewer", %{
      conn: conn,
      creator_token: creator_token,
      book: book
    } do
      create_response = create_club(conn, creator_token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn = get(conn, ~p"/api/clubs/#{club_id}")

      assert %{"data" => %{"id" => ^club_id, "joined_by_user" => false}} =
               json_response(conn, 200)
    end

    test "returns 404 for an unknown club", %{conn: conn} do
      conn = get(conn, ~p"/api/clubs/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/clubs/:id/members" do
    test "lists members, earliest joiner first", %{
      conn: conn,
      creator: creator,
      creator_token: creator_token,
      other: other,
      other_token: other_token,
      book: book
    } do
      create_response = create_club(conn, creator_token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn
      |> put_req_header("authorization", "Bearer #{other_token}")
      |> post(~p"/api/clubs/#{club_id}/membership")

      conn = get(conn, ~p"/api/clubs/#{club_id}/members")

      assert %{"data" => [%{"id" => first_id}, %{"id" => second_id}]} = json_response(conn, 200)
      assert first_id == creator.id
      assert second_id == other.id
    end
  end

  describe "POST /api/clubs/:id/membership" do
    test "joins the club and enrolls the joiner in its Community Health community", %{
      conn: conn,
      creator_token: creator_token,
      other: other,
      other_token: other_token,
      book: book
    } do
      create_response = create_club(conn, creator_token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{other_token}")
        |> post(~p"/api/clubs/#{club_id}/membership")

      assert json_response(conn, 200) == %{"data" => %{"joined" => true}}

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{action: "ensure_member", actor_id: other.id, community_id: "club_#{club_id}"}
      )
    end

    test "joining twice stays joined", %{conn: conn, creator_token: token, book: book} do
      create_response = create_club(conn, token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn = conn |> put_req_header("authorization", "Bearer #{token}")
      post(conn, ~p"/api/clubs/#{club_id}/membership")
      conn2 = post(conn, ~p"/api/clubs/#{club_id}/membership")

      assert json_response(conn2, 200) == %{"data" => %{"joined" => true}}
    end

    test "rejects an unauthenticated request", %{conn: conn, creator_token: token, book: book} do
      create_response = create_club(conn, token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn = post(conn, ~p"/api/clubs/#{club_id}/membership")
      assert json_response(conn, 401)
    end

    test "returns 404 for an unknown club", %{conn: conn, creator_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/clubs/#{Ecto.UUID.generate()}/membership")

      assert json_response(conn, 404)
    end
  end

  describe "DELETE /api/clubs/:id/membership" do
    test "leaves a joined club", %{
      conn: conn,
      creator_token: creator_token,
      other_token: other_token,
      book: book
    } do
      create_response = create_club(conn, creator_token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn = conn |> put_req_header("authorization", "Bearer #{other_token}")
      post(conn, ~p"/api/clubs/#{club_id}/membership")

      conn2 = delete(conn, ~p"/api/clubs/#{club_id}/membership")
      assert json_response(conn2, 200) == %{"data" => %{"joined" => false}}
    end

    test "leaving a club you haven't joined is a no-op", %{
      conn: conn,
      creator_token: creator_token,
      other_token: other_token,
      book: book
    } do
      create_response = create_club(conn, creator_token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{other_token}")
        |> delete(~p"/api/clubs/#{club_id}/membership")

      assert json_response(conn, 200) == %{"data" => %{"joined" => false}}
    end

    test "rejects an unauthenticated request", %{conn: conn, creator_token: token, book: book} do
      create_response = create_club(conn, token, book)
      %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

      conn = delete(conn, ~p"/api/clubs/#{club_id}/membership")
      assert json_response(conn, 401)
    end
  end
end
