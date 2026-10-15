defmodule Api.Usecases.Answer.MarkBestAnswer.MarkBestAnswerUsecase do
  @moduledoc """
  Marks an answer as the best answer to its question — only the question's
  own asker may do this (enforced by the adaptee, not here).

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to record the
  BEST_ANSWER_SELECTED event — this usecase never aliases an
  Infrastructure module directly.
  """

  alias Api.Usecases.Answer.MarkBestAnswer.MarkBestAnswerUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(%MarkBestAnswerUsecaseDto{user: user, answer_id: answer_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee},
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, answer} <- adapter.mark_best_answer(user, answer_id, adaptee) do
      # event_key carries the answer's id, not just the question's, so
      # re-marking a different answer as best on the same question (the
      # asker changing their mind) still records as a distinct event.
      enqueue_community_health.(%{
        action: "record_action",
        actor_id: user.id,
        action_type: "BEST_ANSWER_SELECTED",
        resource_type: "answer",
        resource_id: answer.id,
        community_id: default_community_id(),
        event_key: "answer:best:#{answer.id}"
      })

      {:ok, answer}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
