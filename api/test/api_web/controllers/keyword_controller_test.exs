defmodule ApiWeb.KeywordControllerTest do
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

    {:ok, author} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "author@example.com", "password" => "supersecret", "name" => "Author"}
      })

    {:ok, reader} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "reader@example.com", "password" => "supersecret", "name" => "Reader"}
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: reader, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    %{author: author, reader: reader, access_token: access_token, book: book}
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

  describe "GET /api/keywords/:name" do
    test "returns the keyword's stats and matching posts, newest first", %{
      conn: conn,
      author: author,
      book: book
    } do
      _older = create_post(author, book, %{"keywords" => ["attention"], "thinking" => "Older."})
      newer = create_post(author, book, %{"keywords" => ["attention"], "thinking" => "Newer."})

      conn = get(conn, ~p"/api/keywords/attention")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["name"] == "attention"
      assert data["stats"] == %{"post_count" => 2, "book_count" => 1, "reader_count" => 1}
      assert Enum.map(data["posts"], & &1["thinking"]) == [newer.thinking, "Older."]
    end

    test "name lookup is trimmed/case-insensitive, same as post creation", %{
      conn: conn,
      author: author,
      book: book
    } do
      create_post(author, book, %{"keywords" => ["Nature-Writing"]})

      conn = get(conn, ~p"/api/keywords/nature-writing")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["name"] == "nature-writing"
      assert length(data["posts"]) == 1
    end

    test "counts distinct books and readers, not posts", %{conn: conn, author: author, reader: reader, book: book} do
      {:ok, book2} =
        Catalog.add_book(%AddBookUsecaseDto{attrs: %{"title" => "Deep Work", "author" => "Cal Newport"}})

      create_post(author, book, %{"keywords" => ["focus"]})
      create_post(author, book, %{"keywords" => ["focus"], "thinking" => "Second post, same book+author."})
      create_post(reader, book2, %{"keywords" => ["focus"]})

      conn = get(conn, ~p"/api/keywords/focus")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["stats"] == %{"post_count" => 3, "book_count" => 2, "reader_count" => 2}
    end

    test "lists related keywords that co-occur on the same posts, most shared first", %{
      conn: conn,
      author: author,
      book: book
    } do
      create_post(author, book, %{"keywords" => ["attention", "ecology"]})
      create_post(author, book, %{"keywords" => ["attention", "ecology"], "thinking" => "Second."})
      create_post(author, book, %{"keywords" => ["attention", "focus"], "thinking" => "Third."})

      conn = get(conn, ~p"/api/keywords/attention")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["related_keywords"] == ["ecology", "focus"]
    end

    test "paginates with the before cursor, same convention as the main feed", %{
      conn: conn,
      author: author,
      book: book
    } do
      create_post(author, book, %{"keywords" => ["attention"], "thinking" => "Oldest."})
      middle = create_post(author, book, %{"keywords" => ["attention"], "thinking" => "Middle."})
      _newest = create_post(author, book, %{"keywords" => ["attention"], "thinking" => "Newest."})

      conn = get(conn, ~p"/api/keywords/attention", before: DateTime.to_iso8601(middle.inserted_at))

      assert %{"data" => data} = json_response(conn, 200)
      assert Enum.map(data["posts"], & &1["thinking"]) == ["Oldest."]
    end

    test "annotates liked_by_user/bookmarked_by_user for an authenticated caller", %{
      conn: conn,
      author: author,
      reader: reader,
      access_token: token,
      book: book
    } do
      post = create_post(author, book, %{"keywords" => ["attention"]})

      conn_auth = put_req_header(conn, "authorization", "Bearer #{token}")
      like_conn = post(conn_auth, ~p"/api/posts/#{post.id}/likes")
      assert json_response(like_conn, 200)

      conn2 = get(conn_auth, ~p"/api/keywords/attention")
      assert %{"data" => %{"posts" => [post_data]}} = json_response(conn2, 200)
      assert post_data["liked_by_user"] == true
      assert post_data["bookmarked_by_user"] == false

      _ = reader
    end

    test "works for an unauthenticated caller, with liked/bookmarked false", %{
      conn: conn,
      author: author,
      book: book
    } do
      create_post(author, book, %{"keywords" => ["attention"]})

      conn = get(conn, ~p"/api/keywords/attention")

      assert %{"data" => %{"posts" => [post_data]}} = json_response(conn, 200)
      assert post_data["liked_by_user"] == false
      assert post_data["bookmarked_by_user"] == false
    end

    test "returns 404 for an unknown keyword", %{conn: conn} do
      conn = get(conn, ~p"/api/keywords/does-not-exist")
      assert json_response(conn, 404)
    end
  end
end
