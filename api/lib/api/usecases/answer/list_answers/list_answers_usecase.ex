defmodule Api.Usecases.Answer.ListAnswers.ListAnswersUsecase do
  @moduledoc """
  Lists the answers to a question, the marked best answer first. Knows
  nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Answer.ListAnswers.ListAnswersUsecaseDto

  defstruct [:repository]

  def call(%ListAnswersUsecaseDto{question_id: question_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    {:ok, adapter.list_answers(question_id, adaptee)}
  end
end
