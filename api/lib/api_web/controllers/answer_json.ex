defmodule ApiWeb.AnswerJSON do
  alias Api.Domain.Answer

  def show(%{answer: answer}), do: %{data: data(answer)}
  def index(%{answers: answers}), do: %{data: Enum.map(answers, &data/1)}

  def data(%Answer{} = answer) do
    %{
      id: answer.id,
      question_id: answer.question_id,
      body: answer.body,
      best: answer.best,
      inserted_at: answer.inserted_at,
      user: %{
        id: answer.user.id,
        name: answer.user.name,
        avatar_url: answer.user.avatar_url
      }
    }
  end
end
