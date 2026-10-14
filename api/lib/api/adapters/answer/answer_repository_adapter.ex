defmodule Api.Adapters.Answer.AnswerRepositoryAdapter do
  @moduledoc """
  Adapts an answer repository (the adaptee) to the domain: calls it for the
  database entity/entities, then converts the result(s) into the pure
  Api.Domain.Answer business entity.
  """

  alias Api.Adapters.User.UserRepositoryAdapter
  alias Api.Domain.Answer, as: DomainAnswer

  def create_answer(user, question_id, attrs, adaptee) do
    case adaptee.create_answer(user, question_id, attrs) do
      {:ok, db_answer} -> {:ok, to_domain(db_answer)}
      {:error, :not_found} -> {:error, :not_found}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_answers(question_id, adaptee) do
    adaptee.list_answers(question_id) |> Enum.map(&to_domain/1)
  end

  def mark_best_answer(user, answer_id, adaptee) do
    case adaptee.mark_best_answer(user, answer_id) do
      {:ok, db_answer} -> {:ok, to_domain(db_answer)}
      {:error, :not_found} -> {:error, :not_found}
      {:error, :forbidden} -> {:error, :forbidden}
    end
  end

  @doc "Converts a Postgres answer entity (with its associations preloaded) into the pure domain entity."
  def to_domain(db_answer) do
    %DomainAnswer{
      id: db_answer.id,
      question_id: db_answer.question_id,
      body: db_answer.body,
      best: db_answer.is_best,
      user: UserRepositoryAdapter.to_domain(db_answer.user),
      inserted_at: db_answer.inserted_at,
      updated_at: db_answer.updated_at
    }
  end
end
