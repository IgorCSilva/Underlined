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

  describe "list_posts/1" do
    test "returns posts newest first" do
      user = user_fixture()
      book = book_fixture()

      {:ok, older} =
        Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("passage_text", "Older."))

      {:ok, newer} =
        Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("passage_text", "Newer."))

      assert Enum.map(Posts.list_posts(), & &1.id) == [newer.id, older.id]
    end

    test "before cursor excludes posts at or after that timestamp" do
      user = user_fixture()
      book = book_fixture()

      {:ok, older} =
        Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("passage_text", "Older."))

      {:ok, newer} =
        Posts.create_post(user, @valid_attrs |> Map.put("book_id", book.id) |> Map.put("passage_text", "Newer."))

      cursor = DateTime.to_iso8601(newer.inserted_at)

      assert Enum.map(Posts.list_posts(cursor), & &1.id) == [older.id]
    end

    test "ignores an invalid cursor and returns the first page" do
      user = user_fixture()
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert Enum.map(Posts.list_posts("not-a-timestamp"), & &1.id) == [post.id]
    end

    test "returns an empty list when there are no posts" do
      assert Posts.list_posts() == []
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

  describe "list_posts/2 and get_post/2 liked_by_user annotation" do
    test "flags liked_by_user per the given current_user" do
      user = user_fixture()
      liker = user_fixture(%{"email" => "liker@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert {:ok, _} = Posts.like_post(liker, post.id)

      [listed] = Posts.list_posts(nil, liker)
      assert listed.liked_by_user == true

      [listed_as_author] = Posts.list_posts(nil, user)
      assert listed_as_author.liked_by_user == false

      [listed_anonymous] = Posts.list_posts()
      assert listed_anonymous.liked_by_user == false

      assert Posts.get_post(post.id, liker).liked_by_user == true
      assert Posts.get_post(post.id, user).liked_by_user == false
      assert Posts.get_post(post.id).liked_by_user == false
    end
  end

  describe "like_post/2" do
    test "likes a post and increments its like_count" do
      user = user_fixture()
      liker = user_fixture(%{"email" => "liker@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert {:ok, %{liked: true, like_count: 1}} = Posts.like_post(liker, post.id)
      assert Posts.get_post(post.id).like_count == 1
    end

    test "liking an already-liked post is idempotent" do
      user = user_fixture()
      liker = user_fixture(%{"email" => "liker@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert {:ok, %{liked: true, like_count: 1}} = Posts.like_post(liker, post.id)
      assert {:ok, %{liked: true, like_count: 1}} = Posts.like_post(liker, post.id)
      assert Posts.get_post(post.id).like_count == 1
    end

    test "returns not_found for a missing or invalid post id" do
      liker = user_fixture()

      assert {:error, :not_found} = Posts.like_post(liker, Ecto.UUID.generate())
      assert {:error, :not_found} = Posts.like_post(liker, "not-a-uuid")
    end
  end

  describe "unlike_post/2" do
    test "unlikes a previously-liked post and decrements its like_count" do
      user = user_fixture()
      liker = user_fixture(%{"email" => "liker@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert {:ok, %{liked: true, like_count: 1}} = Posts.like_post(liker, post.id)
      assert {:ok, %{liked: false, like_count: 0}} = Posts.unlike_post(liker, post.id)
      assert Posts.get_post(post.id).like_count == 0
    end

    test "unliking a post that wasn't liked is a no-op" do
      user = user_fixture()
      liker = user_fixture(%{"email" => "liker@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert {:ok, %{liked: false, like_count: 0}} = Posts.unlike_post(liker, post.id)
    end

    test "returns not_found for a missing or invalid post id" do
      liker = user_fixture()

      assert {:error, :not_found} = Posts.unlike_post(liker, Ecto.UUID.generate())
      assert {:error, :not_found} = Posts.unlike_post(liker, "not-a-uuid")
    end
  end

  describe "create_comment/3" do
    test "creates a top-level comment and increments the post's comment_count" do
      user = user_fixture()
      commenter = user_fixture(%{"email" => "commenter1@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert {:ok, comment} = Posts.create_comment(commenter, post.id, %{"body" => "Great read!"})
      assert comment.type == "comment"
      assert comment.body == "Great read!"
      assert comment.parent_comment_id == nil
      assert comment.user.id == commenter.id
      assert Posts.get_post(post.id).comment_count == 1
    end

    test "creates a reply tied to its parent top-level comment" do
      user = user_fixture()
      commenter = user_fixture(%{"email" => "commenter2@example.com"})
      replier = user_fixture(%{"email" => "replier2@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))
      {:ok, parent} = Posts.create_comment(commenter, post.id, %{"body" => "Great read!"})

      assert {:ok, reply} =
               Posts.create_comment(replier, post.id, %{
                 "body" => "Agreed!",
                 "parent_comment_id" => parent.id
               })

      assert reply.type == "reply"
      assert reply.parent_comment_id == parent.id
      assert Posts.get_post(post.id).comment_count == 2
    end

    test "rejects replying to a reply" do
      user = user_fixture()
      commenter = user_fixture(%{"email" => "commenter3@example.com"})
      replier = user_fixture(%{"email" => "replier3@example.com"})
      other = user_fixture(%{"email" => "other3@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))
      {:ok, parent} = Posts.create_comment(commenter, post.id, %{"body" => "Great read!"})
      {:ok, reply} = Posts.create_comment(replier, post.id, %{"body" => "Agreed!", "parent_comment_id" => parent.id})

      assert {:error, :invalid_parent} =
               Posts.create_comment(other, post.id, %{
                 "body" => "Me too!",
                 "parent_comment_id" => reply.id
               })
    end

    test "returns not_found for a missing or invalid post id" do
      commenter = user_fixture()

      assert {:error, :not_found} = Posts.create_comment(commenter, Ecto.UUID.generate(), %{"body" => "Hi"})
      assert {:error, :not_found} = Posts.create_comment(commenter, "not-a-uuid", %{"body" => "Hi"})
    end

    test "requires a non-blank body" do
      user = user_fixture()
      commenter = user_fixture(%{"email" => "commenter4@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      assert {:error, changeset} = Posts.create_comment(commenter, post.id, %{"body" => ""})
      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end

    test "rate limits comment creation per user" do
      user = user_fixture()
      commenter = user_fixture(%{"email" => "commenter5@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      for n <- 1..5 do
        assert {:ok, _comment} = Posts.create_comment(commenter, post.id, %{"body" => "Comment #{n}"})
      end

      assert {:error, :rate_limited} = Posts.create_comment(commenter, post.id, %{"body" => "One too many"})
    end
  end

  describe "list_comments/1" do
    test "returns top-level comments oldest first, each with its replies oldest first" do
      user = user_fixture()
      commenter = user_fixture(%{"email" => "commenter6@example.com"})
      replier = user_fixture(%{"email" => "replier6@example.com"})
      book = book_fixture()
      {:ok, post} = Posts.create_post(user, Map.put(@valid_attrs, "book_id", book.id))

      {:ok, first} = Posts.create_comment(commenter, post.id, %{"body" => "First comment"})
      {:ok, second} = Posts.create_comment(commenter, post.id, %{"body" => "Second comment"})

      {:ok, reply_a} =
        Posts.create_comment(replier, post.id, %{"body" => "Reply A", "parent_comment_id" => first.id})

      {:ok, reply_b} =
        Posts.create_comment(replier, post.id, %{"body" => "Reply B", "parent_comment_id" => first.id})

      [listed_first, listed_second] = Posts.list_comments(post.id)

      assert listed_first.id == first.id
      assert listed_second.id == second.id
      assert Enum.map(listed_first.replies, & &1.id) == [reply_a.id, reply_b.id]
      assert listed_second.replies == []
    end

    test "returns an empty list for a missing or invalid post id" do
      assert Posts.list_comments(Ecto.UUID.generate()) == []
      assert Posts.list_comments("not-a-uuid") == []
    end
  end
end
