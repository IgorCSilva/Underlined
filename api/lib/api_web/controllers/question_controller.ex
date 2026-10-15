defmodule ApiWeb.QuestionController do
  use ApiWeb, :controller

  alias Api.Adapters.Questions
  alias Api.Usecases.Question.CreateQuestion.CreateQuestionUsecaseDto
  alias Api.Usecases.Question.GetQuestion.GetQuestionUsecaseDto

  action_fallback ApiWeb.FallbackController

  def create(conn, %{"book_id" => book_id, "question" => question_params}) do
    with {:ok, question} <-
           Questions.create_question(%CreateQuestionUsecaseDto{
             user: current_user(conn),
             attrs: Map.put(question_params, "book_id", book_id)
           }) do
      conn
      |> put_status(:created)
      |> render(:show, question: question)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, question} <- Questions.get_question(%GetQuestionUsecaseDto{id: id}) do
      render(conn, :show, question: question)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
