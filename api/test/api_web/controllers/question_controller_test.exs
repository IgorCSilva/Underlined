defmodule ApiWeb.QuestionControllerTest do
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

    {:ok, asker} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "asker@example.com", "password" => "supersecret", "name" => "Asker"}
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: asker, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    %{book: book, asker: asker, access_token: access_token}
  end

  describe "POST /api/books/:book_id/questions" do
    test "creates a question when authenticated", %{
      conn: conn,
      book: book,
      access_token: token,
      asker: asker
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books/#{book.id}/questions",
          question: %{"passage_text" => "A short passage.", "body" => "What does this mean?"}
        )

      assert %{"data" => data} = json_response(conn, 201)
      assert data["body"] == "What does this mean?"
      assert data["answer_count"] == 0
      assert data["book"]["id"] == book.id
      assert data["passage"]["text"] == "A short passage."
      assert data["user"]["id"] == asker.id

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{
          action: "record_action",
          actor_id: asker.id,
          action_type: "ASK_QUESTION",
          resource_type: "question",
          resource_id: data["id"],
          community_id: "default"
        }
      )
    end

    test "rejects an unauthenticated request", %{conn: conn, book: book} do
      conn =
        post(conn, ~p"/api/books/#{book.id}/questions",
          question: %{"passage_text" => "A short passage.", "body" => "What does this mean?"}
        )

      assert json_response(conn, 401)
    end

    test "returns 422 for a blank body", %{conn: conn, book: book, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books/#{book.id}/questions",
          question: %{"passage_text" => "A short passage.", "body" => ""}
        )

      assert json_response(conn, 422)
    end

    test "returns 404 for an unknown book", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books/#{Ecto.UUID.generate()}/questions",
          question: %{"passage_text" => "A short passage.", "body" => "What does this mean?"}
        )

      assert json_response(conn, 404)
    end
  end

  describe "GET /api/questions/:id" do
    test "returns a question", %{conn: conn, book: book, access_token: token} do
      create_conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/books/#{book.id}/questions",
          question: %{"passage_text" => "A short passage.", "body" => "What does this mean?"}
        )

      %{"data" => %{"id" => question_id}} = json_response(create_conn, 201)

      conn2 = get(build_conn(), ~p"/api/questions/#{question_id}")
      assert %{"data" => data} = json_response(conn2, 200)
      assert data["id"] == question_id
    end

    test "returns 404 for an unknown question", %{conn: conn} do
      conn = get(conn, ~p"/api/questions/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end
end
