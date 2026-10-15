defmodule ApiWeb.AnswerControllerTest do
  use ApiWeb.ConnCase, async: true
  use Oban.Testing, repo: Api.Repo

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Adapters.Questions
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
  alias Api.Usecases.Question.CreateQuestion.CreateQuestionUsecaseDto
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

    {:ok, answerer} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{
          "email" => "answerer@example.com",
          "password" => "supersecret",
          "name" => "Answerer"
        }
      })

    {:ok, asker_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: asker, remember_me: false})

    {:ok, answerer_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: answerer, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    {:ok, question} =
      Questions.create_question(%CreateQuestionUsecaseDto{
        user: asker,
        attrs: %{
          "book_id" => book.id,
          "passage_text" => "A short passage.",
          "body" => "What does this mean?"
        }
      })

    %{
      question: question,
      asker: asker,
      asker_token: asker_token,
      answerer: answerer,
      answerer_token: answerer_token
    }
  end

  describe "POST /api/questions/:question_id/answers" do
    test "creates an answer when authenticated", %{
      conn: conn,
      question: question,
      answerer_token: token,
      answerer: answerer
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/questions/#{question.id}/answers", answer: %{"body" => "It means X."})

      assert %{"data" => data} = json_response(conn, 201)
      assert data["body"] == "It means X."
      assert data["best"] == false
      assert data["user"]["id"] == answerer.id

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{
          action: "record_action",
          actor_id: answerer.id,
          action_type: "ANSWER",
          resource_type: "answer",
          resource_id: data["id"],
          community_id: "default",
          context: %{question_id: question.id}
        }
      )
    end

    test "rejects an unauthenticated request", %{conn: conn, question: question} do
      conn = post(conn, ~p"/api/questions/#{question.id}/answers", answer: %{"body" => "Nope."})
      assert json_response(conn, 401)
    end

    test "returns 422 for a blank body", %{conn: conn, question: question, answerer_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/questions/#{question.id}/answers", answer: %{"body" => ""})

      assert json_response(conn, 422)
    end

    test "returns 404 for an unknown question", %{conn: conn, answerer_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/questions/#{Ecto.UUID.generate()}/answers", answer: %{"body" => "X"})

      assert json_response(conn, 404)
    end
  end

  describe "GET /api/questions/:question_id/answers" do
    test "lists answers, best first", %{
      conn: conn,
      question: question,
      answerer_token: answerer_token,
      asker_token: asker_token
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{answerer_token}")

      post(authed, ~p"/api/questions/#{question.id}/answers", answer: %{"body" => "First."})

      %{"data" => %{"id" => second_id}} =
        post(authed, ~p"/api/questions/#{question.id}/answers", answer: %{"body" => "Second."})
        |> json_response(201)

      put(
        conn |> put_req_header("authorization", "Bearer #{asker_token}"),
        ~p"/api/answers/#{second_id}/best"
      )

      list_conn = get(build_conn(), ~p"/api/questions/#{question.id}/answers")
      assert %{"data" => [first, second]} = json_response(list_conn, 200)
      assert first["id"] == second_id
      assert first["best"] == true
      assert second["best"] == false
    end

    test "returns an empty list for a question with no answers", %{conn: conn, question: question} do
      conn = get(conn, ~p"/api/questions/#{question.id}/answers")
      assert json_response(conn, 200) == %{"data" => []}
    end
  end

  describe "PUT /api/answers/:id/best" do
    test "lets the asker mark an answer as best", %{
      conn: conn,
      question: question,
      asker_token: asker_token,
      answerer_token: answerer_token
    } do
      %{"data" => %{"id" => answer_id}} =
        conn
        |> put_req_header("authorization", "Bearer #{answerer_token}")
        |> post(~p"/api/questions/#{question.id}/answers", answer: %{"body" => "It means X."})
        |> json_response(201)

      conn2 =
        build_conn()
        |> put_req_header("authorization", "Bearer #{asker_token}")
        |> put(~p"/api/answers/#{answer_id}/best")

      assert %{"data" => data} = json_response(conn2, 200)
      assert data["id"] == answer_id
      assert data["best"] == true

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{
          action: "record_action",
          action_type: "BEST_ANSWER_SELECTED",
          resource_type: "answer",
          resource_id: answer_id,
          community_id: "default"
        }
      )
    end

    test "unmarks the previous best answer when a new one is chosen", %{
      conn: conn,
      question: question,
      asker_token: asker_token,
      answerer_token: answerer_token
    } do
      authed = conn |> put_req_header("authorization", "Bearer #{answerer_token}")

      %{"data" => %{"id" => first_id}} =
        post(authed, ~p"/api/questions/#{question.id}/answers", answer: %{"body" => "First."})
        |> json_response(201)

      %{"data" => %{"id" => second_id}} =
        post(authed, ~p"/api/questions/#{question.id}/answers", answer: %{"body" => "Second."})
        |> json_response(201)

      asker_conn = build_conn() |> put_req_header("authorization", "Bearer #{asker_token}")
      put(asker_conn, ~p"/api/answers/#{first_id}/best")
      put(asker_conn, ~p"/api/answers/#{second_id}/best")

      list_conn = get(build_conn(), ~p"/api/questions/#{question.id}/answers")
      assert %{"data" => answers} = json_response(list_conn, 200)
      assert Enum.find(answers, &(&1["id"] == first_id))["best"] == false
      assert Enum.find(answers, &(&1["id"] == second_id))["best"] == true
    end

    test "rejects marking best from a user who isn't the asker", %{
      conn: conn,
      question: question,
      answerer_token: answerer_token
    } do
      %{"data" => %{"id" => answer_id}} =
        conn
        |> put_req_header("authorization", "Bearer #{answerer_token}")
        |> post(~p"/api/questions/#{question.id}/answers", answer: %{"body" => "It means X."})
        |> json_response(201)

      conn2 =
        build_conn()
        |> put_req_header("authorization", "Bearer #{answerer_token}")
        |> put(~p"/api/answers/#{answer_id}/best")

      assert json_response(conn2, 403)
    end

    test "rejects an unauthenticated request", %{
      conn: conn,
      question: question,
      answerer_token: token
    } do
      %{"data" => %{"id" => answer_id}} =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/questions/#{question.id}/answers", answer: %{"body" => "It means X."})
        |> json_response(201)

      conn2 = put(build_conn(), ~p"/api/answers/#{answer_id}/best")
      assert json_response(conn2, 401)
    end

    test "returns 404 for an unknown answer", %{conn: conn, asker_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/answers/#{Ecto.UUID.generate()}/best")

      assert json_response(conn, 404)
    end
  end
end
