defmodule ApiWeb.DebateControllerTest do
  use ApiWeb.ConnCase, async: true

  import Mox

  alias Api.Adapters.Accounts
  alias Api.Adapters.Catalog
  alias Api.Adapters.Posts
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
        attrs: %{"email" => "reader@example.com", "password" => "supersecret", "name" => "Reader"}
      })

    {:ok, access_token, _refresh_token} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: user, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    {:ok, post_a} = create_post(user, book, "Passage A.", "Thinking A.")
    {:ok, post_b} = create_post(user, book, "Passage B.", "Thinking B.")

    %{user: user, access_token: access_token, post_a: post_a, post_b: post_b}
  end

  defp create_post(user, book, passage_text, thinking) do
    Posts.create_post(%CreatePostUsecaseDto{
      user: user,
      attrs: %{"book_id" => book.id, "passage_text" => passage_text, "thinking" => thinking}
    })
  end

  defp connect(user, post_a, post_b, relationship_type) do
    Posts.connect_posts(%ConnectPostsUsecaseDto{
      user: user,
      post_id: post_a.id,
      related_post_id: post_b.id,
      relationship_type: relationship_type
    })
  end

  describe "GET /api/connections/:id" do
    test "shows both posts of a contradicts connection, unauthenticated", %{
      conn: conn,
      user: user,
      post_a: post_a,
      post_b: post_b
    } do
      {:ok, connection} = connect(user, post_a, post_b, "contradicts")

      conn = get(conn, ~p"/api/connections/#{connection.id}")

      assert %{
               "data" => %{
                 "relationship_type" => "contradicts",
                 "post_a" => %{"id" => post_a_id},
                 "post_b" => %{"id" => post_b_id}
               }
             } = json_response(conn, 200)

      assert Enum.sort([post_a_id, post_b_id]) == Enum.sort([post_a.id, post_b.id])
    end

    test "returns 404 for a non-contradicts connection", %{
      conn: conn,
      user: user,
      post_a: post_a,
      post_b: post_b
    } do
      {:ok, connection} = connect(user, post_a, post_b, "similar_idea")

      conn = get(conn, ~p"/api/connections/#{connection.id}")

      assert json_response(conn, 404)
    end

    test "returns 404 for an unknown connection id", %{conn: conn} do
      conn = get(conn, ~p"/api/connections/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end
end
