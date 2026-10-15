defmodule ApiWeb.AnswerController do
  use ApiWeb, :controller

  alias Api.Adapters.Questions
  alias Api.Usecases.Answer.CreateAnswer.CreateAnswerUsecaseDto
  alias Api.Usecases.Answer.ListAnswers.ListAnswersUsecaseDto
  alias Api.Usecases.Answer.MarkBestAnswer.MarkBestAnswerUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, %{"question_id" => question_id}) do
    with {:ok, answers} <-
           Questions.list_answers(%ListAnswersUsecaseDto{question_id: question_id}) do
      render(conn, :index, answers: answers)
    end
  end

  def create(conn, %{"question_id" => question_id, "answer" => answer_params}) do
    with {:ok, answer} <-
           Questions.create_answer(%CreateAnswerUsecaseDto{
             user: current_user(conn),
             question_id: question_id,
             attrs: answer_params
           }) do
      conn
      |> put_status(:created)
      |> render(:show, answer: answer)
    end
  end

  def mark_best(conn, %{"id" => id}) do
    with {:ok, answer} <-
           Questions.mark_best_answer(%MarkBestAnswerUsecaseDto{
             user: current_user(conn),
             answer_id: id
           }) do
      render(conn, :show, answer: answer)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
