defmodule Api.Infrastructure.Repository.Question.Postgres.QuestionRepository do
  @moduledoc """
  Postgres-backed data access for the question entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Book.Postgres.{Book, BookRepository}
  alias Api.Infrastructure.Repository.Passage.Postgres.Passage
  alias Api.Infrastructure.Repository.Question.Postgres.Question
  alias Api.Repo

  @preloads [:book, :passage, :user]

  @doc """
  Creates a passage + question tied to a book, same shape as
  `PostRepository.create_post/1` — a question is just a different kind of
  thing one can say about a freshly-written passage.
  """
  def create_question(user, attrs) do
    with %Book{} = book <- BookRepository.get_book(attrs["book_id"]) || {:error, :not_found} do
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
        |> Ecto.Multi.insert(:question, fn %{passage: passage} ->
          Question.changeset(%Question{}, %{
            "user_id" => user.id,
            "book_id" => book.id,
            "passage_id" => passage.id,
            "body" => attrs["body"]
          })
        end)

      case Repo.transaction(multi) do
        {:ok, %{question: question}} -> {:ok, Repo.preload(question, @preloads)}
        {:error, _op, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  def get_question(id) do
    case fetch_question(id) do
      nil -> nil
      question -> Repo.preload(question, @preloads)
    end
  end

  @doc "Fetches a question by id, without preloads. Returns `nil` if missing/invalid."
  def fetch_question(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(Question, uuid)
      :error -> nil
    end
  end

  @doc "Questions for a book, newest first."
  def list_questions_for_book(book_id) do
    case Ecto.UUID.cast(book_id) do
      {:ok, uuid} ->
        Question
        |> where([q], q.book_id == ^uuid)
        |> order_by(desc: :inserted_at)
        |> Repo.all()
        |> Repo.preload(@preloads)

      :error ->
        []
    end
  end
end
