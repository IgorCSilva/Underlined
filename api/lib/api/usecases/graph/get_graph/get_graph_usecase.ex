defmodule Api.Usecases.Graph.GetGraph.GetGraphUsecase do
  @moduledoc """
  A user's personal idea graph: their own posts and keywords as nodes,
  the connections and keyword-tags between them as edges.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Graph.GetGraph.GetGraphUsecaseDto

  defstruct [:repository]

  def call(%GetGraphUsecaseDto{user_id: user_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.get_graph(user_id, adaptee)
  end
end
