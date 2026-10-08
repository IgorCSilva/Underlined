defmodule Api.Adapters.Chains do
  @moduledoc """
  Facade over the idea-chain usecases.

  Callers build the DTO the target usecase expects and pass it in; this
  module only routes each DTO to its usecase.
  """

  alias Api.Usecases.Chain.AddChainItem.AddChainItemUsecase
  alias Api.Usecases.Chain.CreateChain.CreateChainUsecase
  alias Api.Usecases.Chain.GetChain.GetChainUsecase
  alias Api.Usecases.Chain.ListChains.ListChainsUsecase
  alias Api.Usecases.Chain.ReorderChainItems.ReorderChainItemsUsecase

  def create_chain(dto) do
    CreateChainUsecase.call(dto, %CreateChainUsecase{repository: chain_repository()})
  end

  def list_chains(dto) do
    ListChainsUsecase.call(dto, %ListChainsUsecase{repository: chain_repository()})
  end

  def get_chain(dto) do
    GetChainUsecase.call(dto, %GetChainUsecase{repository: chain_repository()})
  end

  def add_chain_item(dto) do
    AddChainItemUsecase.call(dto, %AddChainItemUsecase{repository: chain_repository()})
  end

  def reorder_chain_items(dto) do
    ReorderChainItemsUsecase.call(dto, %ReorderChainItemsUsecase{repository: chain_repository()})
  end

  defp chain_repository, do: Application.get_env(:api, :chain_repository) |> Map.new()
end
