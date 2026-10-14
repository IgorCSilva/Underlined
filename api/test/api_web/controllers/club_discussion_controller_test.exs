defmodule ApiWeb.ClubDiscussionControllerTest do
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

    create_response =
      conn
      |> put_req_header("authorization", "Bearer #{creator_token}")
      |> post(~p"/api/books/#{book.id}/clubs", %{"club" => %{"name" => "Sapiens Readers"}})

    %{"data" => %{"id" => club_id}} = json_response(create_response, 201)

    %{
      creator: creator,
      other: other,
      creator_token: creator_token,
      other_token: other_token,
      book: book,
      club_id: club_id
    }
  end

  defp auth(conn, token), do: put_req_header(conn, "authorization", "Bearer #{token}")

  defp create_chapter(conn, token, club_id, attrs) do
    conn |> auth(token) |> post(~p"/api/clubs/#{club_id}/chapters", %{"chapter" => attrs})
  end

  describe "POST /api/clubs/:club_id/chapters" do
    test "the creator can add the first chapter and choose the unit word", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      conn =
        create_chapter(conn, token, club_id, %{
          "label" => "Chapter 1 - The first day",
          "chapter_unit_label" => "Chapter"
        })

      assert %{
               "data" => %{
                 "label" => "Chapter 1 - The first day",
                 "position" => 1,
                 "current" => false
               }
             } = json_response(conn, 201)
    end

    test "a second chapter gets the next position", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      create_chapter(conn, token, club_id, %{"label" => "Chapter 1"})
      conn = create_chapter(conn, token, club_id, %{"label" => "Chapter 2"})

      assert %{"data" => %{"position" => 2}} = json_response(conn, 201)
    end

    test "a non-creator member cannot add a chapter", %{
      conn: conn,
      other_token: token,
      club_id: club_id
    } do
      conn = create_chapter(conn, token, club_id, %{"label" => "Chapter 1"})
      assert json_response(conn, 403)
    end

    test "rejects an unauthenticated request", %{conn: conn, club_id: club_id} do
      conn =
        post(conn, ~p"/api/clubs/#{club_id}/chapters", %{"chapter" => %{"label" => "Chapter 1"}})

      assert json_response(conn, 401)
    end
  end

  describe "GET /api/clubs/:club_id/chapters" do
    test "lists chapters in schedule order, flagging the current one", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      create_chapter(conn, token, club_id, %{"label" => "Chapter 1"})
      create_response = create_chapter(conn, token, club_id, %{"label" => "Chapter 2"})
      %{"data" => %{"id" => chapter_2_id}} = json_response(create_response, 201)

      conn
      |> auth(token)
      |> put(~p"/api/clubs/#{club_id}/chapters/#{chapter_2_id}/current")

      conn = get(conn, ~p"/api/clubs/#{club_id}/chapters")

      assert %{
               "data" => [
                 %{"label" => "Chapter 1", "current" => false},
                 %{"label" => "Chapter 2", "current" => true}
               ]
             } = json_response(conn, 200)
    end
  end

  describe "PUT /api/clubs/:club_id/chapters/:id/current" do
    test "the creator advances the club's current chapter", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      create_response = create_chapter(conn, token, club_id, %{"label" => "Chapter 1"})
      %{"data" => %{"id" => chapter_id}} = json_response(create_response, 201)

      conn =
        conn
        |> auth(token)
        |> put(~p"/api/clubs/#{club_id}/chapters/#{chapter_id}/current")

      assert %{"data" => %{"id" => ^chapter_id, "current" => true}} = json_response(conn, 200)

      show_conn = get(build_conn(), ~p"/api/clubs/#{club_id}")

      assert %{"data" => %{"current_chapter_label" => "Chapter 1"}} =
               json_response(show_conn, 200)
    end

    test "a non-creator member cannot set the current chapter", %{
      conn: conn,
      creator_token: creator_token,
      other_token: other_token,
      club_id: club_id
    } do
      create_response = create_chapter(conn, creator_token, club_id, %{"label" => "Chapter 1"})
      %{"data" => %{"id" => chapter_id}} = json_response(create_response, 201)

      conn =
        conn
        |> auth(other_token)
        |> put(~p"/api/clubs/#{club_id}/chapters/#{chapter_id}/current")

      assert json_response(conn, 403)
    end

    test "returns 422 for a chapter that doesn't belong to this club", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      conn =
        conn
        |> auth(token)
        |> put(~p"/api/clubs/#{club_id}/chapters/#{Ecto.UUID.generate()}/current")

      assert json_response(conn, 422)
    end
  end

  describe "POST /api/clubs/:club_id/posts" do
    test "a member can post to the discussion, optionally tagged to a chapter", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      chapter_response = create_chapter(conn, token, club_id, %{"label" => "Chapter 1"})
      %{"data" => %{"id" => chapter_id}} = json_response(chapter_response, 201)

      conn =
        conn
        |> auth(token)
        |> post(~p"/api/clubs/#{club_id}/posts", %{
          "post" => %{"body" => "What did everyone think?", "chapter_id" => chapter_id}
        })

      assert %{
               "data" => %{
                 "body" => "What did everyone think?",
                 "chapter" => %{"id" => ^chapter_id},
                 "comment_count" => 0
               }
             } = json_response(conn, 201)
    end

    test "a general (untagged) post is allowed", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      conn =
        conn
        |> auth(token)
        |> post(~p"/api/clubs/#{club_id}/posts", %{"post" => %{"body" => "General chat"}})

      assert %{"data" => %{"body" => "General chat", "chapter" => nil}} = json_response(conn, 201)
    end

    test "a non-member cannot post", %{conn: conn, other_token: token, club_id: club_id} do
      conn =
        conn
        |> auth(token)
        |> post(~p"/api/clubs/#{club_id}/posts", %{"post" => %{"body" => "Can I post?"}})

      assert json_response(conn, 403)
    end

    test "rejects a chapter that doesn't belong to this club", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      conn =
        conn
        |> auth(token)
        |> post(~p"/api/clubs/#{club_id}/posts", %{
          "post" => %{"body" => "Hello", "chapter_id" => Ecto.UUID.generate()}
        })

      assert json_response(conn, 422)
    end

    test "rejects an unauthenticated request", %{conn: conn, club_id: club_id} do
      conn = post(conn, ~p"/api/clubs/#{club_id}/posts", %{"post" => %{"body" => "Hello"}})
      assert json_response(conn, 401)
    end
  end

  describe "GET /api/clubs/:club_id/posts" do
    test "lists posts, general discussion before chapter-scoped posts", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      chapter_response = create_chapter(conn, token, club_id, %{"label" => "Chapter 1"})
      %{"data" => %{"id" => chapter_id}} = json_response(chapter_response, 201)

      conn
      |> auth(token)
      |> post(~p"/api/clubs/#{club_id}/posts", %{
        "post" => %{"body" => "Tagged to chapter 1", "chapter_id" => chapter_id}
      })

      conn
      |> auth(token)
      |> post(~p"/api/clubs/#{club_id}/posts", %{"post" => %{"body" => "General chat"}})

      conn = get(conn, ~p"/api/clubs/#{club_id}/posts")

      assert %{
               "data" => [
                 %{"body" => "General chat", "spoiler_blocked" => false},
                 %{"body" => nil, "spoiler_blocked" => true}
               ]
             } = json_response(conn, 200)
    end
  end

  describe "spoiler protection on GET /api/clubs/:club_id/posts" do
    setup %{conn: conn, creator_token: token, club_id: club_id} do
      ch1 = create_chapter(conn, token, club_id, %{"label" => "Chapter 1"})
      %{"data" => %{"id" => chapter_1_id}} = json_response(ch1, 201)

      ch2 = create_chapter(conn, token, club_id, %{"label" => "Chapter 2"})
      %{"data" => %{"id" => chapter_2_id}} = json_response(ch2, 201)

      conn
      |> auth(token)
      |> post(~p"/api/clubs/#{club_id}/posts", %{
        "post" => %{"body" => "Thoughts on chapter 1", "chapter_id" => chapter_1_id}
      })

      conn
      |> auth(token)
      |> post(~p"/api/clubs/#{club_id}/posts", %{
        "post" => %{"body" => "Thoughts on chapter 2", "chapter_id" => chapter_2_id}
      })

      %{chapter_1_id: chapter_1_id, chapter_2_id: chapter_2_id}
    end

    test "a reader who hasn't set any progress has every chapter-tagged post blocked", %{
      conn: conn,
      other_token: token,
      club_id: club_id
    } do
      conn = conn |> auth(token) |> get(~p"/api/clubs/#{club_id}/posts")

      assert %{
               "data" => [
                 %{"body" => nil, "spoiler_blocked" => true, "chapter" => %{"position" => 1}},
                 %{"body" => nil, "spoiler_blocked" => true, "chapter" => %{"position" => 2}}
               ]
             } = json_response(conn, 200)
    end

    test "setting progress to chapter 1 reveals chapter 1 but keeps chapter 2 blocked", %{
      conn: conn,
      other_token: token,
      club_id: club_id,
      chapter_1_id: chapter_1_id
    } do
      conn
      |> auth(token)
      |> put(~p"/api/clubs/#{club_id}/reading_progress", %{
        "reading_progress" => %{"chapter_id" => chapter_1_id}
      })

      conn = conn |> auth(token) |> get(~p"/api/clubs/#{club_id}/posts")

      assert %{
               "data" => [
                 %{"body" => "Thoughts on chapter 1", "spoiler_blocked" => false},
                 %{"body" => nil, "spoiler_blocked" => true}
               ]
             } = json_response(conn, 200)
    end

    test "the club's creator still has their own unset progress block chapter posts", %{
      conn: conn,
      creator_token: token,
      club_id: club_id
    } do
      conn = conn |> auth(token) |> get(~p"/api/clubs/#{club_id}/posts")

      assert %{"data" => [%{"spoiler_blocked" => true}, %{"spoiler_blocked" => true}]} =
               json_response(conn, 200)
    end

    test "GET /api/club_posts/:id/reveal returns the full post regardless of progress", %{
      conn: conn,
      club_id: club_id
    } do
      index_conn = get(conn, ~p"/api/clubs/#{club_id}/posts")
      %{"data" => [%{"id" => post_id} | _]} = json_response(index_conn, 200)

      conn = get(conn, ~p"/api/club_posts/#{post_id}/reveal")

      assert %{"data" => %{"body" => "Thoughts on chapter 1", "spoiler_blocked" => false}} =
               json_response(conn, 200)
    end
  end

  describe "club post comments" do
    setup %{conn: conn, creator_token: token, club_id: club_id} do
      post_response =
        conn
        |> auth(token)
        |> post(~p"/api/clubs/#{club_id}/posts", %{"post" => %{"body" => "Thoughts?"}})

      %{"data" => %{"id" => club_post_id}} = json_response(post_response, 201)
      %{club_post_id: club_post_id}
    end

    test "a member can comment on a club post", %{
      conn: conn,
      creator_token: token,
      club_post_id: club_post_id
    } do
      conn =
        conn
        |> auth(token)
        |> post(~p"/api/club_posts/#{club_post_id}/comments", %{
          "comment" => %{"body" => "I loved it"}
        })

      assert %{"data" => %{"body" => "I loved it", "type" => "comment"}} =
               json_response(conn, 201)

      refute Map.has_key?(json_response(conn, 201)["data"], "side")
    end

    test "a non-member cannot comment", %{
      conn: conn,
      other_token: token,
      club_post_id: club_post_id
    } do
      conn =
        conn
        |> auth(token)
        |> post(~p"/api/club_posts/#{club_post_id}/comments", %{"comment" => %{"body" => "Hey"}})

      assert json_response(conn, 403)
    end

    test "comments are listed oldest first", %{
      conn: conn,
      creator_token: token,
      club_post_id: club_post_id
    } do
      conn
      |> auth(token)
      |> post(~p"/api/club_posts/#{club_post_id}/comments", %{"comment" => %{"body" => "First"}})

      conn
      |> auth(token)
      |> post(~p"/api/club_posts/#{club_post_id}/comments", %{"comment" => %{"body" => "Second"}})

      conn = get(conn, ~p"/api/club_posts/#{club_post_id}/comments")

      assert %{"data" => [%{"body" => "First"}, %{"body" => "Second"}]} = json_response(conn, 200)
    end

    test "the author can edit their own comment", %{
      conn: conn,
      creator_token: token,
      club_post_id: club_post_id
    } do
      create_response =
        conn
        |> auth(token)
        |> post(~p"/api/club_posts/#{club_post_id}/comments", %{
          "comment" => %{"body" => "Typo hre"}
        })

      %{"data" => %{"id" => comment_id}} = json_response(create_response, 201)

      conn =
        conn
        |> auth(token)
        |> put(~p"/api/club_posts/#{club_post_id}/comments/#{comment_id}", %{
          "comment" => %{"body" => "Typo here"}
        })

      assert %{"data" => %{"body" => "Typo here"}} = json_response(conn, 200)
    end

    test "rejects an unauthenticated comment", %{conn: conn, club_post_id: club_post_id} do
      conn =
        post(conn, ~p"/api/club_posts/#{club_post_id}/comments", %{
          "comment" => %{"body" => "Hey"}
        })

      assert json_response(conn, 401)
    end
  end
end
