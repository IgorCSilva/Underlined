defmodule Api.CatalogTest do
  use Api.DataCase, async: true

  alias Api.Catalog
  alias Api.Catalog.Book

  @valid_attrs %{"title" => "Thinking, Fast and Slow", "author" => "Daniel Kahneman"}

  defp book_fixture(attrs \\ %{}) do
    {:ok, book} = Catalog.add_book(Map.merge(@valid_attrs, attrs))
    book
  end

  describe "list_books/1" do
    test "returns all books ordered by newest first when the query is blank" do
      older = book_fixture(%{"title" => "Older Book", "author" => "Author A"})
      newer = book_fixture(%{"title" => "Newer Book", "author" => "Author B"})

      assert [^newer, ^older] = Catalog.list_books(nil)
      assert [^newer, ^older] = Catalog.list_books("")
    end

    test "matches on title or author via full-text search" do
      book = book_fixture(%{"title" => "Sapiens", "author" => "Yuval Noah Harari"})
      _other = book_fixture(%{"title" => "Atomic Habits", "author" => "James Clear"})

      assert [found] = Catalog.list_books("sapiens")
      assert found.id == book.id

      assert [found_by_author] = Catalog.list_books("Harari")
      assert found_by_author.id == book.id
    end

    test "ranks a stronger match above a weaker one" do
      strong = book_fixture(%{"title" => "Deep Work Deep Work", "author" => "Cal Newport"})
      weak = book_fixture(%{"title" => "Deep", "author" => "Work"})

      assert [first, second] = Catalog.list_books("Deep Work")
      assert first.id == strong.id
      assert second.id == weak.id
    end

    test "returns an empty list when nothing matches" do
      book_fixture()
      assert Catalog.list_books("nonexistent-xyz") == []
    end
  end

  describe "get_book/1" do
    test "returns the book by id" do
      book = book_fixture()
      assert %Book{id: id} = Catalog.get_book(book.id)
      assert id == book.id
    end

    test "returns nil for an unknown or invalid id" do
      assert Catalog.get_book(Ecto.UUID.generate()) == nil
      assert Catalog.get_book("not-a-uuid") == nil
    end
  end

  describe "add_book/1" do
    test "creates a new book" do
      assert {:ok, %Book{} = book} = Catalog.add_book(@valid_attrs)
      assert book.title == "Thinking, Fast and Slow"
      assert book.author == "Daniel Kahneman"
    end

    test "requires title and author" do
      assert {:error, changeset} = Catalog.add_book(%{})
      assert %{title: ["can't be blank"], author: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates cover_url is an http(s) URL when present" do
      assert {:error, changeset} = Catalog.add_book(Map.put(@valid_attrs, "cover_url", "not-a-url"))
      assert "must be a valid http(s) URL" in errors_on(changeset).cover_url
    end

    test "allows a blank cover_url" do
      assert {:ok, book} = Catalog.add_book(Map.put(@valid_attrs, "cover_url", ""))
      assert book.cover_url == nil
    end

    test "returns the existing book instead of a duplicate (case-insensitive)" do
      existing = book_fixture()

      assert {:ok, book} =
               Catalog.add_book(%{"title" => "thinking, fast and slow", "author" => "DANIEL KAHNEMAN"})

      assert book.id == existing.id
      assert Repo.aggregate(Book, :count) == 1
    end
  end
end
