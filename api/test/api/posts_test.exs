defmodule Api.PostsTest do
  use Api.DataCase, async: true

  alias Api.{Accounts, Catalog, Posts}
  alias Api.Posts.{Post, Keyword}

  @valid_attrs %{
    "passage_text" => "A short passage.",
    "thinking" => "This changed how I think.",
    "keywords" => ["Attention", " attention ", "nature-writing"]
  }

  defp user_fixture(attrs \\ %{}) do
    base = %{"email" => "reader@example.com", "password" => "supersecret", "name" => "Reader One"}
    {:ok, user} = Accounts.register_user(Map.merge(base, attrs))
    user
  end

  defp book_fixture(attrs \\ %{}) do
    base = %{"title" => "Sapiens", "author" => "Yuval Noah Harari"}
    {:ok, book} = Catalog.add_book(Map.merge(base, attrs))
    book
  end

  describe "create_post/2" do
    test "creates a post with its passage and deduped/normalized keywords" do
      user = user_fixture()
      book = book_fixture()

      assert {:ok, %Post{} = post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert post.thinking == "This changed how I think."
      assert post.book.id == book.id
      assert post.passage.text == "A short passage."
      assert post.user.id == user.id
      assert Enum.sort(Enum.map(post.keywords, & &1.name)) == ["attention", "nature-writing"]
    end

    test "reuses an existing keyword across posts instead of duplicating it" do
      user = user_fixture()
      book = book_fixture()

      {:ok, first} =
        Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("keywords", ["ecology"]))

      {:ok, second} =
        Posts.create_post(
          user,
          @valid_attrs
          |> Map.put("book_id", book.id)
          |> Map.put("passage_text", "Another passage.")
          |> Map.put("keywords", ["ECOLOGY"])
        )

      [first_keyword] = first.keywords
      [second_keyword] = second.keywords
      assert first_keyword.id == second_keyword.id
      assert Repo.aggregate(Keyword, :count) == 1
    end

    test "allows publishing without any keywords" do
      user = user_fixture()
      book = book_fixture()

      assert {:ok, %Post{keywords: []}} =
               Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("keywords", []))
    end

    test "returns not_found for a missing or invalid book_id" do
      user = user_fixture()

      assert {:error, :not_found} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", Ecto.UUID.generate()))
      assert {:error, :not_found} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", "not-a-uuid"))
    end

    test "requires a passage" do
      user = user_fixture()
      book = book_fixture()

      assert {:error, changeset} =
               Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("passage_text", ""))

      assert %{text: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires a thinking takeaway" do
      user = user_fixture()
      book = book_fixture()

      assert {:error, changeset} =
               Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("thinking", ""))

      assert %{thinking: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects more than 8 keywords" do
      user = user_fixture()
      book = book_fixture()
      many_keywords = for n <- 1..9, do: "kw#{n}"

      assert {:error, changeset} =
               Posts.create_post(
                 user,
                 @valid_attrs |> Map.put("book_id", book.id) |> Map.put("keywords", many_keywords)
               )

      assert %{keyword_names: [msg]} = errors_on(changeset)
      assert msg =~ "up to 8 keywords"
    end
  end

  describe "get_post/1" do
    test "returns the post with associations preloaded" do
      user = user_fixture()
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      found = Posts.get_post(post.id)
      assert found.id == post.id
      assert found.book.id == book.id
      assert found.passage.text == post.passage.text
    end

    test "returns nil for an unknown or invalid id" do
      assert Posts.get_post(Ecto.UUID.generate()) == nil
      assert Posts.get_post("not-a-uuid") == nil
    end
  end
end
