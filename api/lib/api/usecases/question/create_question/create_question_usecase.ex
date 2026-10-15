defmodule Api.Usecases.Question.CreateQuestion.CreateQuestionUsecase do
  @moduledoc """
  Publishes a passage + question tied to a book.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}` and a
  `community_health_enqueuer` function used to record the ASK_QUESTION
  event — this usecase never aliases an Infrastructure module directly.
  """

  alias Api.Usecases.Question.CreateQuestion.CreateQuestionUsecaseDto

  defstruct [:repository, :community_health_enqueuer]

  def call(%CreateQuestionUsecaseDto{user: user, attrs: attrs}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee},
        community_health_enqueuer: enqueue_community_health
      }) do
    with {:ok, question} <- adapter.create_question(user, attrs, adaptee) do
      # event_key is idempotent on the question's own id — a question is
      # only ever created once, same reasoning as CreatePostUsecase's
      # `post:create:` key.
      enqueue_community_health.(%{
        action: "record_action",
        actor_id: user.id,
        action_type: "ASK_QUESTION",
        resource_type: "question",
        resource_id: question.id,
        community_id: default_community_id(),
        event_key: "question:create:#{question.id}"
      })

      {:ok, question}
    end
  end

  defp default_community_id,
    do: Application.get_env(:api, :community_health_default_community, "default")
end
