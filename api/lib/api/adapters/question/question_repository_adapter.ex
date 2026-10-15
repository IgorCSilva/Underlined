defmodule Api.Adapters.Question.QuestionRepositoryAdapter do
  @moduledoc """
  Adapts a question repository (the adaptee) to the domain: calls it for
  the database entity/entities, then converts the result(s) into the pure
  Api.Domain.Question business entity.
  """

  alias Api.Adapters.Book.BookRepositoryAdapter
  alias Api.Adapters.Passage.PassageRepositoryAdapter
  alias Api.Adapters.User.UserRepositoryAdapter
  alias Api.Domain.Question, as: DomainQuestion

  def create_question(user, attrs, adaptee) do
    case adaptee.create_question(user, attrs) do
      {:ok, db_question} -> {:ok, to_domain(db_question)}
      {:error, :not_found} -> {:error, :not_found}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def get_question(id, adaptee) do
    case adaptee.get_question(id) do
      nil -> nil
      db_question -> to_domain(db_question)
    end
  end

  def list_questions_for_book(book_id, adaptee) do
    adaptee.list_questions_for_book(book_id) |> Enum.map(&to_domain/1)
  end

  @doc "Converts a Postgres question entity (with its associations preloaded) into the pure domain entity."
  def to_domain(db_question) do
    %DomainQuestion{
      id: db_question.id,
      body: db_question.body,
      answer_count: db_question.answer_count,
      book: BookRepositoryAdapter.to_domain(db_question.book),
      passage: PassageRepositoryAdapter.to_domain(db_question.passage),
      user: UserRepositoryAdapter.to_domain(db_question.user),
      inserted_at: db_question.inserted_at,
      updated_at: db_question.updated_at
    }
  end
end
