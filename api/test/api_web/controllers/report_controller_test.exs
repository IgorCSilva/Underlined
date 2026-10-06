defmodule ApiWeb.ReportControllerTest do
  use ApiWeb.ConnCase, async: true
  use Oban.Testing, repo: Api.Repo

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Adapters.Posts
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
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

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    {:ok, post} =
      Posts.create_post(%CreatePostUsecaseDto{
        user: user,
        attrs: %{
          "book_id" => book.id,
          "passage_text" => "A short passage.",
          "thinking" => "This changed how I think.",
          "keywords" => ["attention"]
        }
      })

    %{user: user, access_token: access_token, post: post}
  end

  describe "GET /api/reports/reasons" do
    test "returns active rules when Community Health is available", %{
      conn: conn,
      access_token: token
    } do
      Api.CommunityHealthMock
      |> expect(:list_rules, fn "default" ->
        {:ok, [%{code: "PERSONAL_ATTACK", name: "Personal attack", description: nil, severity: "high"}]}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/reports/reasons")

      assert %{
               "data" => %{
                 "community_health_available" => true,
                 "rules" => [%{"code" => "PERSONAL_ATTACK"}]
               }
             } = json_response(conn, 200)
    end

    test "degrades to an empty list when Community Health is unavailable", %{
      conn: conn,
      access_token: token
    } do
      Api.CommunityHealthMock
      |> expect(:list_rules, fn "default" -> {:error, :unavailable} end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/reports/reasons")

      assert %{"data" => %{"community_health_available" => false, "rules" => []}} =
               json_response(conn, 200)
    end

    test "rejects an unauthenticated request", %{conn: conn} do
      conn = get(conn, ~p"/api/reports/reasons")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/reports" do
    test "enqueues a report job when authenticated", %{
      conn: conn,
      access_token: token,
      post: post
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/reports",
          report: %{
            "resource_type" => "post",
            "resource_id" => post.id,
            "reason" => "PERSONAL_ATTACK",
            "description" => "attacks another reader"
          }
        )

      assert %{"data" => %{"status" => "queued"}} = json_response(conn, 201)

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{
          action: "submit_report",
          resource_type: "post",
          resource_id: post.id,
          community_id: "default",
          reason: "PERSONAL_ATTACK",
          description: "attacks another reader"
        }
      )
    end

    test "rejects an unauthenticated request", %{conn: conn, post: post} do
      conn =
        post(conn, ~p"/api/reports",
          report: %{"resource_type" => "post", "resource_id" => post.id, "reason" => "SPAM"}
        )

      assert json_response(conn, 401)
    end

    test "returns validation errors for a missing reason", %{
      conn: conn,
      access_token: token,
      post: post
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/reports",
          report: %{"resource_type" => "post", "resource_id" => post.id}
        )

      assert json_response(conn, 422)
    end

    test "returns validation errors for an invalid resource_type", %{
      conn: conn,
      access_token: token,
      post: post
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/reports",
          report: %{
            "resource_type" => "book",
            "resource_id" => post.id,
            "reason" => "PERSONAL_ATTACK"
          }
        )

      assert json_response(conn, 422)
    end
  end
end
