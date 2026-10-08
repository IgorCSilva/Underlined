defmodule ApiWeb.ProfileControllerTest do
  use ApiWeb.ConnCase, async: true
  use Oban.Testing, repo: Api.Repo

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Adapters.Posts
  alias Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker
  alias Api.Infrastructure.Repository.InterestProfile.Postgres.InterestProfileRepository
  alias Api.Usecases.Book.AddBook.AddBookUsecaseDto
  alias Api.Usecases.Connection.ConnectPosts.ConnectPostsUsecaseDto
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

  describe "GET /api/users/:id" do
    test "returns a user's public profile", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}")

      assert %{"data" => %{"id" => id, "name" => "Reader One", "followed_by_user" => false}} =
               json_response(conn, 200)

      assert id == user.id
    end

    test "returns 404 for an unknown user", %{conn: conn} do
      conn = get(conn, ~p"/api/users/999999")
      assert json_response(conn, 404)
    end

    test "reports followed_by_user true once the caller follows them", %{conn: conn, user: user} do
      {:ok, viewer} =
        Accounts.register_user(%RegisterUserUsecaseDto{
          attrs: %{
            "email" => "viewer@example.com",
            "password" => "supersecret",
            "name" => "Viewer"
          }
        })

      {:ok, viewer_token, _refresh_token} =
        Accounts.create_session(%CreateSessionUsecaseDto{user: viewer, remember_me: false})

      follow_conn =
        conn
        |> put_req_header("authorization", "Bearer #{viewer_token}")
        |> post(~p"/api/users/#{user.id}/follow")

      assert json_response(follow_conn, 200)

      authed_show =
        build_conn()
        |> put_req_header("authorization", "Bearer #{viewer_token}")
        |> get(~p"/api/users/#{user.id}")

      assert %{"data" => %{"followed_by_user" => true}} = json_response(authed_show, 200)

      anon_show = get(build_conn(), ~p"/api/users/#{user.id}")
      assert %{"data" => %{"followed_by_user" => false}} = json_response(anon_show, 200)
    end
  end

  describe "PUT /api/me" do
    test "picks one of the fixed preset avatars", %{conn: conn, access_token: token} do
      [preset | _] = Api.Infrastructure.Repository.User.Postgres.User.avatar_choices()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me", user: %{avatar_url: preset})

      assert %{"data" => %{"id" => id, "avatar_url" => ^preset}} = json_response(conn, 200)

      assert_enqueued(
        worker: CommunityHealthWorker,
        args: %{action: "ensure_member", actor_id: id, community_id: "default"}
      )
    end

    test "rejects an avatar_url outside the preset list", %{conn: conn, access_token: token} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me", user: %{avatar_url: "https://evil.example/x.png"})

      assert json_response(conn, 422)
    end
  end

  describe "PUT /api/me/avatar" do
    test "uploads an avatar and updates the profile", %{
      conn: conn,
      user: user,
      access_token: token
    } do
      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, "image/png" ->
        assert id == user.id
        {:ok, "http://minio/avatars/#{id}.png"}
      end)

      path = Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.png")
      File.write!(path, "fake-png-bytes")

      upload = %Plug.Upload{path: path, filename: "avatar.png", content_type: "image/png"}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me/avatar", avatar: upload)

      assert %{"data" => %{"avatar_url" => "http://minio/avatars/" <> _}} =
               json_response(conn, 200)
    end

    test "deletes the previous avatar object when a second upload succeeds", %{
      conn: conn,
      user: user,
      access_token: token
    } do
      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-1.png"}
      end)

      path1 =
        Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.png")

      File.write!(path1, "fake-png-bytes-1")
      upload1 = %Plug.Upload{path: path1, filename: "avatar.png", content_type: "image/png"}

      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/me/avatar", avatar: upload1)
      |> json_response(200)

      Api.ObjectStoreMock
      |> expect(:put_avatar, fn id, _binary, _content_type ->
        {:ok, "http://minio/avatars/#{id}-2.png"}
      end)
      |> expect(:delete_avatar, fn url ->
        assert url == "http://minio/avatars/#{user.id}-1.png"
        :ok
      end)

      path2 =
        Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.png")

      File.write!(path2, "fake-png-bytes-2")
      upload2 = %Plug.Upload{path: path2, filename: "avatar.png", content_type: "image/png"}

      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> put(~p"/api/me/avatar", avatar: upload2)
      |> json_response(200)
    end

    test "rejects a disallowed content type", %{conn: conn, access_token: token} do
      path = Path.join(System.tmp_dir!(), "avatar_test_#{System.unique_integer([:positive])}.txt")
      File.write!(path, "not an image")
      upload = %Plug.Upload{path: path, filename: "avatar.txt", content_type: "text/plain"}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/me/avatar", avatar: upload)

      assert json_response(conn, 422)
    end
  end

  describe "GET /api/users/:id/interests" do
    defp create_post(user, book, keywords, passage_text) do
      {:ok, post} =
        Posts.create_post(%CreatePostUsecaseDto{
          user: user,
          attrs: %{
            "book_id" => book.id,
            "passage_text" => passage_text,
            "thinking" => "Thinking.",
            "keywords" => keywords
          }
        })

      post
    end

    setup do
      {:ok, book} =
        Catalog.add_book(%AddBookUsecaseDto{attrs: %{"title" => "Sapiens", "author" => "Harari"}})

      {:ok, other} =
        Accounts.register_user(%RegisterUserUsecaseDto{
          attrs: %{"email" => "other@example.com", "password" => "supersecret", "name" => "Other Reader"}
        })

      %{book: book, other: other}
    end

    test "returns keyword usage counts, most-used first", %{conn: conn, user: user, book: book} do
      create_post(user, book, ["attention", "nature-writing"], "First.")
      create_post(user, book, ["attention"], "Second.")
      InterestProfileRepository.recompute(user.id)

      conn = get(conn, ~p"/api/users/#{user.id}/interests")

      assert %{"data" => %{"interest_profile" => profile}} = json_response(conn, 200)
      assert profile == [
               %{"keyword" => "attention", "post_count" => 2},
               %{"keyword" => "nature-writing", "post_count" => 1}
             ]
    end

    test "ranks similar readers by shared keyword overlap", %{
      conn: conn,
      user: user,
      book: book,
      other: other
    } do
      create_post(user, book, ["attention", "nature-writing"], "Mine.")
      create_post(other, book, ["attention", "nature-writing"], "Theirs too.")
      InterestProfileRepository.recompute(user.id)
      InterestProfileRepository.recompute(other.id)

      conn = get(conn, ~p"/api/users/#{user.id}/interests")

      assert %{"data" => %{"similar_readers" => [%{"id" => id, "shared_score" => 2}]}} =
               json_response(conn, 200)

      assert id == other.id
    end

    test "returns empty lists for a user with no posts", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}/interests")

      assert json_response(conn, 200) == %{"data" => %{"interest_profile" => [], "similar_readers" => []}}
    end

    test "returns 404 for an unknown user", %{conn: conn} do
      conn = get(conn, ~p"/api/users/999999/interests")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/users/:id/graph" do
    setup do
      {:ok, book} =
        Catalog.add_book(%AddBookUsecaseDto{attrs: %{"title" => "Sapiens", "author" => "Harari"}})

      %{book: book}
    end

    test "returns post and keyword nodes, keyword edges, for a user with posts", %{
      conn: conn,
      user: user,
      book: book
    } do
      post = create_post(user, book, ["attention", "nature-writing"], "First.")

      conn = get(conn, ~p"/api/users/#{user.id}/graph")

      assert %{"data" => %{"nodes" => nodes, "edges" => edges}} = json_response(conn, 200)

      post_nodes = Enum.filter(nodes, &(&1["type"] == "post"))
      keyword_nodes = Enum.filter(nodes, &(&1["type"] == "keyword"))
      assert [%{"id" => post_id, "post" => %{"id" => post_id}}] = post_nodes
      assert post_id == post.id
      assert Enum.map(keyword_nodes, & &1["keyword"]["name"]) |> Enum.sort() ==
               ["attention", "nature-writing"]

      keyword_edges = Enum.filter(edges, &(&1["type"] == "keyword"))
      assert length(keyword_edges) == 2
      assert Enum.all?(keyword_edges, &(&1["source_id"] == post.id))
    end

    test "includes a connection edge only between the user's own posts", %{
      conn: conn,
      user: user,
      book: book
    } do
      post_a = create_post(user, book, [], "First.")
      post_b = create_post(user, book, [], "Second.")

      {:ok, other} =
        Accounts.register_user(%RegisterUserUsecaseDto{
          attrs: %{"email" => "other@example.com", "password" => "supersecret", "name" => "Other"}
        })

      other_post = create_post(other, book, [], "Not mine.")

      {:ok, _connection} =
        Posts.connect_posts(%ConnectPostsUsecaseDto{
          user: user,
          post_id: post_a.id,
          related_post_id: post_b.id,
          relationship_type: "expands_on"
        })

      {:ok, _connection} =
        Posts.connect_posts(%ConnectPostsUsecaseDto{
          user: user,
          post_id: post_a.id,
          related_post_id: other_post.id,
          relationship_type: "contradicts"
        })

      conn = get(conn, ~p"/api/users/#{user.id}/graph")

      assert %{"data" => %{"nodes" => nodes, "edges" => edges}} = json_response(conn, 200)

      post_ids = nodes |> Enum.filter(&(&1["type"] == "post")) |> Enum.map(& &1["id"])
      assert Enum.sort(post_ids) == Enum.sort([post_a.id, post_b.id])

      connection_edges = Enum.reject(edges, &(&1["type"] == "keyword"))
      assert [%{"source_id" => source_id, "target_id" => target_id, "type" => "expands_on"}] =
               connection_edges

      assert Enum.sort([source_id, target_id]) == Enum.sort([post_a.id, post_b.id])
    end

    test "returns empty nodes/edges for a user with no posts", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}/graph")
      assert json_response(conn, 200) == %{"data" => %{"nodes" => [], "edges" => []}}
    end

    test "returns 404 for an unknown user", %{conn: conn} do
      conn = get(conn, ~p"/api/users/999999/graph")
      assert json_response(conn, 404)
    end
  end

  describe "GET /api/users/:id/community_health" do
    test "returns the reputation level and trust level when Community Health is available", %{
      conn: conn,
      user: user
    } do
      Api.CommunityHealthMock
      |> expect(:get_reputation, fn %{actor_id: actor_id, community_id: "default"} ->
        assert actor_id == user.id
        {:ok, %{score: 60, level: 3}}
      end)
      |> expect(:get_trust_level, fn %{actor_id: actor_id, community_id: "default"} ->
        assert actor_id == user.id
        {:ok, %{trust_level: "medium"}}
      end)

      conn = get(conn, ~p"/api/users/#{user.id}/community_health")

      assert json_response(conn, 200) == %{
               "data" => %{
                 "reputation_level" => 3,
                 "trust_level" => "medium",
                 "community_health_available" => true
               }
             }
    end

    test "fails closed when Community Health is unavailable", %{conn: conn, user: user} do
      Api.CommunityHealthMock
      |> expect(:get_reputation, fn _params -> {:error, :unavailable} end)
      |> expect(:get_trust_level, fn _params -> {:error, :unavailable} end)

      conn = get(conn, ~p"/api/users/#{user.id}/community_health")

      assert json_response(conn, 200) == %{
               "data" => %{
                 "reputation_level" => nil,
                 "trust_level" => nil,
                 "community_health_available" => false
               }
             }
    end

    test "returns 404 for an unknown user", %{conn: conn} do
      conn = get(conn, ~p"/api/users/999999/community_health")
      assert json_response(conn, 404)
    end
  end
end
