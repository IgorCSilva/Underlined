defmodule Api.Usecases.Question.GetQuestion.GetQuestionUsecase do
  @moduledoc """
  Fetches a single question. Knows nothing about adapters or
  infrastructure: the caller injects a `repository` of shape
  `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Question.GetQuestion.GetQuestionUsecaseDto

  defstruct [:repository]

  def call(%GetQuestionUsecaseDto{id: id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    case adapter.get_question(id, adaptee) do
      nil -> {:error, :not_found}
      question -> {:ok, question}
    end
  end
end
