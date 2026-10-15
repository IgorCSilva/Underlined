defmodule Api.Usecases.Answer.CreateAnswer.CreateAnswerUsecase do
  @moduledoc """
  Submits an answer to a question.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to record the ANSWER event —
  this usecase never aliases an Infrastructure module directly.
  """

  alias Api.Usecases.Answer.CreateAnswer.CreateAnswerUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(
        %CreateAnswerUsecaseDto{user: user, question_id: question_id, attrs: attrs},
        %__MODULE__{
          repository: %{adapter: adapter, adaptee: adaptee},
          community_health_enqueuer: enqueue_community_health
        }
      ) do
    with {:ok, answer} <- adapter.create_answer(user, question_id, attrs, adaptee) do
      # event_key is idempotent on the answer's own id — an answer is only
      # ever created once, same reasoning as CreateCommentUsecase's
      # `comment:create:` key.
      enqueue_community_health.(%{
        action: "record_action",
        actor_id: user.id,
        action_type: "ANSWER",
        resource_type: "answer",
        resource_id: answer.id,
        community_id: default_community_id(),
        event_key: "answer:create:#{answer.id}",
        context: %{question_id: question_id}
      })

      {:ok, answer}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
