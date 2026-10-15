defmodule Api.Infrastructure.Repository.Answer.Postgres.AnswerRepository do
  @moduledoc """
  Postgres-backed data access for the answer entity.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Answer.Postgres.Answer
  alias Api.Infrastructure.Repository.Question.Postgres.{Question, QuestionRepository}
  alias Api.Repo

  @preloads [:user]

  @doc """
  Creates an answer to a question, incrementing the question's cached
  `answer_count` in the same transaction.
  """
  def create_answer(user, question_id, attrs) do
    case QuestionRepository.fetch_question(question_id) do
      nil ->
        {:error, :not_found}

      question ->
        multi =
          Ecto.Multi.new()
          |> Ecto.Multi.insert(
            :answer,
            Answer.changeset(%Answer{}, %{
              "user_id" => user.id,
              "question_id" => question.id,
              "body" => attrs["body"]
            })
          )
          |> Ecto.Multi.update_all(
            :question,
            fn _ -> where(Question, id: ^question.id) end,
            inc: [answer_count: 1]
          )

        case Repo.transaction(multi) do
          {:ok, %{answer: answer}} -> {:ok, Repo.preload(answer, @preloads)}
          {:error, :answer, changeset, _changes} -> {:error, changeset}
        end
    end
  end

  @doc "Answers for a question, the marked best answer first, then oldest first."
  def list_answers(question_id) do
    case Ecto.UUID.cast(question_id) do
      {:ok, uuid} ->
        Answer
        |> where([a], a.question_id == ^uuid)
        |> order_by([a], desc: a.is_best, asc: a.inserted_at)
        |> Repo.all()
        |> Repo.preload(@preloads)

      :error ->
        []
    end
  end

  @doc """
  Marks `answer_id` as the best answer to its question — only the question's
  own asker may do this. Unmarks any previously-marked best answer for that
  question in the same transaction, since only one may hold the title at a
  time (enforced by the DB's partial unique index too).
  """
  def mark_best_answer(user, answer_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(answer_id),
         %Answer{} = answer <- Repo.get(Answer, uuid) || {:error, :not_found},
         %Question{} = question <- Repo.get(Question, answer.question_id) do
      if question.user_id != user.id do
        {:error, :forbidden}
      else
        multi =
          Ecto.Multi.new()
          |> Ecto.Multi.update_all(
            :unmark_previous,
            fn _ -> where(Answer, question_id: ^question.id, is_best: true) end,
            set: [is_best: false]
          )
          |> Ecto.Multi.update(:answer, Ecto.Changeset.change(answer, is_best: true))

        case Repo.transaction(multi) do
          {:ok, %{answer: answer}} -> {:ok, Repo.preload(answer, @preloads, force: true)}
        end
      end
    else
      {:error, :not_found} -> {:error, :not_found}
      :error -> {:error, :not_found}
    end
  end
end
