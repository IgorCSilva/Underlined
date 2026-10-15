defmodule ApiWeb.QuestionJSON do
  alias Api.Domain.Question

  def show(%{question: question}), do: %{data: data(question)}
  def index(%{questions: questions}), do: %{data: Enum.map(questions, &data/1)}

  def data(%Question{} = question) do
    %{
      id: question.id,
      body: question.body,
      answer_count: question.answer_count,
      inserted_at: question.inserted_at,
      book: %{
        id: question.book.id,
        title: question.book.title,
        author: question.book.author,
        cover_url: question.book.cover_url
      },
      passage: %{
        id: question.passage.id,
        text: question.passage.text
      },
      user: %{
        id: question.user.id,
        name: question.user.name,
        avatar_url: question.user.avatar_url
      }
    }
  end
end
