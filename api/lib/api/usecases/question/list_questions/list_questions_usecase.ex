defmodule Api.Usecases.Question.ListQuestions.ListQuestionsUsecase do
  @moduledoc """
  Lists the questions asked about a book, newest first. Knows nothing
  about adapters or infrastructure: the caller injects a `repository` of
  shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Question.ListQuestions.ListQuestionsUsecaseDto

  defstruct [:repository]

  def call(%ListQuestionsUsecaseDto{book_id: book_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    {:ok, adapter.list_questions_for_book(book_id, adaptee)}
  end
end
