defmodule Api.Adapters.Questions do
  @moduledoc """
  Facade over the question/answer usecases.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Answer.CreateAnswer.CreateAnswerUsecase
  alias Api.Usecases.Answer.ListAnswers.ListAnswersUsecase
  alias Api.Usecases.Answer.MarkBestAnswer.MarkBestAnswerUsecase
  alias Api.Usecases.Question.CreateQuestion.CreateQuestionUsecase
  alias Api.Usecases.Question.GetQuestion.GetQuestionUsecase
  alias Api.Usecases.Question.ListQuestions.ListQuestionsUsecase

  def create_question(dto) do
    CreateQuestionUsecase.call(dto, %CreateQuestionUsecase{
      repository: question_repository(),
      community_health_enqueuer: community_health_enqueuer()
    })
  end

  def get_question(dto) do
    GetQuestionUsecase.call(dto, %GetQuestionUsecase{repository: question_repository()})
  end

  def list_questions(dto) do
    ListQuestionsUsecase.call(dto, %ListQuestionsUsecase{repository: question_repository()})
  end

  def create_answer(dto) do
    CreateAnswerUsecase.call(dto, %CreateAnswerUsecase{
      repository: answer_repository(),
      community_health_enqueuer: community_health_enqueuer()
    })
  end

  def list_answers(dto) do
    ListAnswersUsecase.call(dto, %ListAnswersUsecase{repository: answer_repository()})
  end

  def mark_best_answer(dto) do
    MarkBestAnswerUsecase.call(dto, %MarkBestAnswerUsecase{
      repository: answer_repository(),
      community_health_enqueuer: community_health_enqueuer()
    })
  end

  defp question_repository, do: Application.get_env(:api, :question_repository) |> Map.new()
  defp answer_repository, do: Application.get_env(:api, :answer_repository) |> Map.new()

  defp community_health_enqueuer,
    do:
      Application.get_env(
        :api,
        :community_health_enqueuer,
        &Api.Infrastructure.Health.HealthyCommunity.CommunityHealthWorker.enqueue/1
      )
end
