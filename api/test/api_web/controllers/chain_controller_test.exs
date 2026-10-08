defmodule ApiWeb.ChainControllerTest do
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

    {:ok, user} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "author@example.com", "password" => "supersecret", "name" => "Author"}
      })

    {:ok, other_user} =
      Accounts.register_user(%RegisterUserUsecaseDto{
        attrs: %{"email" => "other@example.com", "password" => "supersecret", "name" => "Other"}
      })

    {:ok, access_token, _} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: user, remember_me: false})

    {:ok, other_access_token, _} =
      Accounts.create_session(%CreateSessionUsecaseDto{user: other_user, remember_me: false})

    {:ok, book} =
      Catalog.add_book(%AddBookUsecaseDto{
        attrs: %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
      })

    {:ok, post_a} = create_post(user, book, "Passage A.", "Thinking A.")
    {:ok, post_b} = create_post(user, book, "Passage B.", "Thinking B.")

    %{
      user: user,
      access_token: access_token,
      other_access_token: other_access_token,
      book: book,
      post_a: post_a,
      post_b: post_b
    }
  end

  defp create_post(user, book, passage_text, thinking) do
    Posts.create_post(%CreatePostUsecaseDto{
      user: user,
      attrs: %{"book_id" => book.id, "passage_text" => passage_text, "thinking" => thinking}
    })
  end

  defp create_chain(conn, token, title) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> post(~p"/api/chains", chain: %{"title" => title})
  end

  defp add_item(conn, token, chain_id, post_id) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> post(~p"/api/chains/#{chain_id}/items", item: %{"post_id" => post_id})
  end

  describe "POST /api/chains" do
    test "creates an empty chain when authenticated", %{conn: conn, access_token: token} do
      conn = create_chain(conn, token, "Four books that changed how I think")

      assert %{"data" => %{"title" => "Four books that changed how I think", "items" => []}} =
               json_response(conn, 201)
    end

    test "rejects a blank title", %{conn: conn, access_token: token} do
      conn = create_chain(conn, token, "")
      assert json_response(conn, 422)
    end

    test "rejects an unauthenticated request", %{conn: conn} do
      conn = post(conn, ~p"/api/chains", chain: %{"title" => "nope"})
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/chains/:chain_id/items" do
    test "appends a post to the end of the chain, in order", %{
      conn: conn,
      access_token: token,
      post_a: post_a,
      post_b: post_b
    } do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]

      conn1 = add_item(conn, token, chain["id"], post_a.id)
      assert %{"data" => %{"items" => [%{"position" => 0, "post" => %{"id" => a_id}}]}} =
               json_response(conn1, 200)
      assert a_id == post_a.id

      conn2 = add_item(conn, token, chain["id"], post_b.id)

      assert %{
               "data" => %{
                 "items" => [
                   %{"position" => 0, "post" => %{"id" => first_id}},
                   %{"position" => 1, "post" => %{"id" => second_id}}
                 ]
               }
             } = json_response(conn2, 200)

      assert first_id == post_a.id
      assert second_id == post_b.id
    end

    test "returns 404 for an unknown chain", %{conn: conn, access_token: token, post_a: post_a} do
      conn =
        add_item(conn, token, Ecto.UUID.generate(), post_a.id)

      assert json_response(conn, 404)
    end

    test "returns 404 for an unknown post", %{conn: conn, access_token: token} do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      conn = add_item(conn, token, chain["id"], Ecto.UUID.generate())
      assert json_response(conn, 404)
    end

    test "rejects adding to a chain authored by someone else", %{
      conn: conn,
      access_token: token,
      other_access_token: other_token,
      post_a: post_a
    } do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      conn = add_item(conn, other_token, chain["id"], post_a.id)
      assert json_response(conn, 403)
    end

    test "rejects an unauthenticated request", %{conn: conn, access_token: token, post_a: post_a} do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      conn = post(conn, ~p"/api/chains/#{chain["id"]}/items", item: %{"post_id" => post_a.id})
      assert json_response(conn, 401)
    end
  end

  describe "PUT /api/chains/:chain_id/items" do
    test "reorders the chain's items to match the given order", %{
      conn: conn,
      access_token: token,
      post_a: post_a,
      post_b: post_b
    } do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      _ = add_item(conn, token, chain["id"], post_a.id)
      added = json_response(add_item(conn, token, chain["id"], post_b.id), 200)["data"]

      [item_a, item_b] = added["items"]

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/chains/#{chain["id"]}/items", item_ids: [item_b["id"], item_a["id"]])

      assert %{
               "data" => %{
                 "items" => [
                   %{"position" => 0, "post" => %{"id" => first_id}},
                   %{"position" => 1, "post" => %{"id" => second_id}}
                 ]
               }
             } = json_response(conn, 200)

      assert first_id == post_b.id
      assert second_id == post_a.id
    end

    test "rejects a reorder that doesn't list every existing item exactly once", %{
      conn: conn,
      access_token: token,
      post_a: post_a,
      post_b: post_b
    } do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      _ = add_item(conn, token, chain["id"], post_a.id)
      added = json_response(add_item(conn, token, chain["id"], post_b.id), 200)["data"]
      [item_a, _item_b] = added["items"]

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(~p"/api/chains/#{chain["id"]}/items", item_ids: [item_a["id"]])

      assert json_response(conn, 422)
    end

    test "rejects reordering a chain authored by someone else", %{
      conn: conn,
      access_token: token,
      other_access_token: other_token,
      post_a: post_a
    } do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      added = json_response(add_item(conn, token, chain["id"], post_a.id), 200)["data"]
      [item_a] = added["items"]

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{other_token}")
        |> put(~p"/api/chains/#{chain["id"]}/items", item_ids: [item_a["id"]])

      assert json_response(conn, 403)
    end
  end

  describe "GET /api/chains" do
    test "lists chains newest first, each with its ordered items", %{
      conn: conn,
      access_token: token,
      post_a: post_a
    } do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      _ = add_item(conn, token, chain["id"], post_a.id)

      conn = get(conn, ~p"/api/chains")

      assert %{"data" => [%{"id" => id, "items" => [%{"post" => %{"id" => post_id}}]}]} =
               json_response(conn, 200)

      assert id == chain["id"]
      assert post_id == post_a.id
    end
  end

  describe "GET /api/chains/:id" do
    test "shows a single chain with its ordered items", %{
      conn: conn,
      access_token: token,
      post_a: post_a
    } do
      chain = json_response(create_chain(conn, token, "Chain"), 201)["data"]
      _ = add_item(conn, token, chain["id"], post_a.id)

      conn = get(conn, ~p"/api/chains/#{chain["id"]}")

      assert %{"data" => %{"id" => id, "items" => [%{"post" => %{"id" => post_id}}]}} =
               json_response(conn, 200)

      assert id == chain["id"]
      assert post_id == post_a.id
    end

    test "returns 404 for an unknown chain", %{conn: conn} do
      conn = get(conn, ~p"/api/chains/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end
end
