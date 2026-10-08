defmodule Api.Adapters.Graphs do
  @moduledoc """
  Facade over the idea-graph usecase.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Graph.GetGraph.GetGraphUsecase

  def get_graph(dto) do
    GetGraphUsecase.call(dto, %GetGraphUsecase{repository: graph_repository()})
  end

  defp graph_repository, do: Application.get_env(:api, :graph_repository) |> Map.new()
end
