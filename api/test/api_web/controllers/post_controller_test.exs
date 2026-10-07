defmodule ApiWeb.PostControllerTest do
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
                 "id" => post_id,
                 "thinking" => "This changed how I think.",
                 "book" => %{"id" => book_id},
                 "passage" => %{"text" => "A short passage."},
                 "keywords" => keywords
               }
             } = json_response(conn, 201)

      assert book_id == book.id
      assert Enum.sort(keywords) == ["attention", "nature-writing"]

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{
          action: "record_action",
          action_type: "CREATE",
          resource_type: "post",
          resource_id: post_id,
          community_id: "default",
          event_key: "post:create:#{post_id}"
        }
      )
    end

    test "rejects an unauthenticated request", %{conn: conn, book: book} do
      conn = post(conn, ~p"/api/posts", post: Map.put(@valid_post_params, "book_id", book.id))
      assert json_response(conn, 401)
    end

    test "returns validation errors", %{conn: conn, access_token: token, book: book} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts",
          post: @valid_post_params |> Map.put("book_id", book.id) |> Map.put("thinking", "")
        )

      assert json_response(conn, 422)
    end

    test "returns a 422, not a 500, for a passage text over the 300-char limit", %{
      conn: conn,
      access_token: token,
      book: book
    } do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts",
          post:
            @valid_post_params
            |> Map.put("book_id", book.id)
            |> Map.put("passage_text", String.duplicate("a", 301))
        )

      assert %{"errors" => %{"text" => _}} = json_response(conn, 422)
    end

    test "returns 404 when the book doesn't exist", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts",
          post: Map.put(@valid_post_params, "book_id", Ecto.UUID.generate())
        )

      assert json_response(conn, 404)
    end
  end

  describe "GET /api/posts" do
    test "lists posts newest first without authentication", %{
      conn: conn,
      access_token: token,
      book: book
    } do
      conn1 =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts",
          post:
            @valid_post_params |> Map.put("book_id", book.id) |> Map.put("passage_text", "First.")
        )

      %{"data" => %{"id" => first_id}} = json_response(conn1, 201)

      conn2 =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts",
          post:
            @valid_post_params
            |> Map.put("book_id", book.id)
            |> Map.put("passage_text", "Second.")
        )

      %{"data" => %{"id" => second_id}} = json_response(conn2, 201)

      conn = get(build_conn(), ~p"/api/posts")
      assert %{"data" => [%{"id" => ^second_id}, %{"id" => ^first_id}]} = json_response(conn, 200)
    end

    test "returns an empty list when there are no posts", %{conn: conn} do
      conn = get(conn, ~p"/api/posts")
      assert json_response(conn, 200) == %{"data" => []}
    end
  end

  describe "GET /api/posts/following" do
    test "lists only posts from followed users", %{conn: conn, access_token: token, book: book} do
      {:ok, followed} =
        Accounts.register_user(%RegisterUserUsecaseDto{
          attrs: %{
            "email" => "followed@example.com",
            "password" => "supersecret",
            "name" => "Followed Author"
          }
        })

      {:ok, post} =
        Posts.create_post(%CreatePostUsecaseDto{
          user: followed,
          attrs: Map.put(@valid_post_params, "book_id", book.id)
        })

      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/users/#{followed.id}/follow")

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/posts/following")

      assert %{"data" => [%{"id" => id}]} = json_response(conn, 200)
      assert id == post.id
    end

    test "excludes posts from users not followed, including the caller's own posts", %{
      conn: conn,
      access_token: token,
      book: book
    } do
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/posts", post: Map.put(@valid_post_params, "book_id", book.id))

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/posts/following")

      assert json_response(conn, 200) == %{"data" => []}
    end

    test "rejects an unauthenticated request", %{conn: conn} do
      conn = get(conn, ~p"/api/posts/following")
      assert json_response(conn, 401)
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

      assert %{"data" => %{"like_count" => 1, "liked_by_user" => true}} =
               json_response(authed_show, 200)

      anon_show = get(build_conn(), ~p"/api/posts/#{id}")

      assert %{"data" => %{"like_count" => 1, "liked_by_user" => false}} =
               json_response(anon_show, 200)
    end

    test "falls back to an anonymous response instead of 401ing when the token is invalid or expired",
         %{conn: conn, access_token: token, book: book} do
      create_conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(~p"/api/posts", post: Map.put(@valid_post_params, "book_id", book.id))

      %{"data" => %{"id" => id}} = json_response(create_conn, 201)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer not-a-real-token")
        |> get(~p"/api/posts/#{id}")

      assert %{"data" => %{"id" => ^id, "liked_by_user" => false}} = json_response(conn, 200)
    end
  end

  describe "GET /api/posts/:id/related" do
    defp create_post(user, book, keywords, passage_text) do
      {:ok, post} =
        Posts.create_post(%CreatePostUsecaseDto{
          user: user,
          attrs:
            @valid_post_params
            |> Map.put("book_id", book.id)
            |> Map.put("keywords", keywords)
            |> Map.put("passage_text", passage_text)
        })

      post
    end

    test "returns posts sharing a keyword, most shared keywords first, excluding itself and unrelated posts",
         %{conn: conn, user: user, book: book} do
      target = create_post(user, book, ["attention", "nature-writing"], "Target.")
      two_shared = create_post(user, book, ["attention", "nature-writing"], "Two shared.")
      one_shared = create_post(user, book, ["attention"], "One shared.")
      _unrelated = create_post(user, book, ["unrelated"], "Unrelated.")
      _no_keywords = create_post(user, book, [], "No keywords.")

      conn = get(conn, ~p"/api/posts/#{target.id}/related")

      assert %{"data" => [%{"id" => first_id}, %{"id" => second_id}]} = json_response(conn, 200)
      assert first_id == two_shared.id
      assert second_id == one_shared.id
    end

    test "returns an empty list for a post with no keywords", %{conn: conn, user: user, book: book} do
      target = create_post(user, book, [], "No keywords.")
      _other = create_post(user, book, ["attention"], "Other.")

      conn = get(conn, ~p"/api/posts/#{target.id}/related")

      assert json_response(conn, 200) == %{"data" => []}
    end

    test "annotates liked_by_user/bookmarked_by_user for an authenticated caller, not for anonymous",
         %{access_token: token, user: user, book: book} do
      target = create_post(user, book, ["attention"], "Target.")
      related = create_post(user, book, ["attention"], "Related.")

      build_conn()
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(~p"/api/posts/#{related.id}/likes")

      authed_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(~p"/api/posts/#{target.id}/related")

      assert %{"data" => [%{"id" => id, "liked_by_user" => true}]} = json_response(authed_conn, 200)
      assert id == related.id

      anon_conn = get(build_conn(), ~p"/api/posts/#{target.id}/related")
      assert %{"data" => [%{"liked_by_user" => false}]} = json_response(anon_conn, 200)
    end

    test "returns 404 for an unknown post", %{conn: conn} do
      conn = get(conn, ~p"/api/posts/#{Ecto.UUID.generate()}/related")
      assert json_response(conn, 404)
    end
  end
end
