defmodule Api.Posts do
  @moduledoc """
  The Posts context: publishing a passage + takeaway + keywords tied to a book (Step 3).
  """

  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Catalog
  alias Api.Posts.{Post, Passage, Keyword}

  @preloads [:book, :passage, :keywords, :user]

  def create_post(%User{} = user, attrs) do
    with %Catalog.Book{} = book <- Catalog.get_book(attrs["book_id"]) || {:error, :not_found} do
      keyword_names = normalize_keyword_names(attrs["keywords"])

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :passage,
          Passage.changeset(%Passage{}, %{
            "book_id" => book.id,
            "user_id" => user.id,
            "text" => attrs["passage_text"]
          })
        )
        |> Ecto.Multi.insert(:post, fn %{passage: passage} ->
          Post.changeset(%Post{}, %{
            "user_id" => user.id,
            "book_id" => book.id,
            "passage_id" => passage.id,
            "thinking" => attrs["thinking"],
            "keyword_names" => keyword_names
          })
        end)
        |> Ecto.Multi.update(:post_with_keywords, fn %{post: post} ->
          keywords = Enum.map(keyword_names, &get_or_create_keyword/1)

          post
          |> Repo.preload(:keywords)
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:keywords, keywords)
        end)

      case Repo.transaction(multi) do
        {:ok, %{post_with_keywords: post}} -> {:ok, Repo.preload(post, @preloads)}
        {:error, _op, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  def get_post(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> uuid |> get_post_by_uuid()
      :error -> nil
    end
  end

  defp get_post_by_uuid(uuid) do
    case Repo.get(Post, uuid) do
      nil -> nil
      post -> Repo.preload(post, @preloads)
    end
  end

  defp normalize_keyword_names(names) when is_list(names) do
    names
    |> Enum.map(&normalize_keyword/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp normalize_keyword_names(_names), do: []

  defp normalize_keyword(name) when is_binary(name), do: name |> String.trim() |> String.downcase()
  defp normalize_keyword(_name), do: ""

  defp get_or_create_keyword(name) do
    case Repo.get_by(Keyword, name: name) do
      nil ->
        {:ok, keyword} = %Keyword{} |> Keyword.changeset(%{name: name}) |> Repo.insert()
        keyword

      keyword ->
        keyword
    end
  end
end
