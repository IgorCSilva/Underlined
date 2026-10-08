defmodule Api.Usecases.Debate.GetDebate.GetDebateUsecase do
  @moduledoc """
  Fetches a single `contradicts` connection by its own id, resolved to both
  posts it links.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Debate.GetDebate.GetDebateUsecaseDto

  defstruct [:repository]

  def call(%GetDebateUsecaseDto{id: id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_debate(id, adaptee)
  end
end
