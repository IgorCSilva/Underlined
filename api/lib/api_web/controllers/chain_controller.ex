defmodule ApiWeb.ChainController do
  use ApiWeb, :controller

  alias Api.Adapters.Chains
  alias Api.Usecases.Chain.AddChainItem.AddChainItemUsecaseDto
  alias Api.Usecases.Chain.CreateChain.CreateChainUsecaseDto
  alias Api.Usecases.Chain.GetChain.GetChainUsecaseDto
  alias Api.Usecases.Chain.ListChains.ListChainsUsecaseDto
  alias Api.Usecases.Chain.ReorderChainItems.ReorderChainItemsUsecaseDto

  action_fallback ApiWeb.FallbackController

  def index(conn, _params) do
    chains = Chains.list_chains(%ListChainsUsecaseDto{})
    render(conn, :index, chains: chains)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, chain} <- Chains.get_chain(%GetChainUsecaseDto{id: id}) do
      render(conn, :show, chain: chain)
    end
  end

  def create(conn, %{"chain" => chain_params}) do
    with {:ok, chain} <-
           Chains.create_chain(%CreateChainUsecaseDto{
             user: current_user(conn),
             title: chain_params["title"]
           }) do
      conn
      |> put_status(:created)
      |> render(:show, chain: chain)
    end
  end

  def add_item(conn, %{"chain_id" => chain_id, "item" => item_params}) do
    with {:ok, chain} <-
           Chains.add_chain_item(%AddChainItemUsecaseDto{
             user: current_user(conn),
             chain_id: chain_id,
             post_id: item_params["post_id"]
           }) do
      render(conn, :show, chain: chain)
    end
  end

  def reorder_items(conn, %{"chain_id" => chain_id, "item_ids" => item_ids}) do
    with {:ok, chain} <-
           Chains.reorder_chain_items(%ReorderChainItemsUsecaseDto{
             user: current_user(conn),
             chain_id: chain_id,
             item_ids: item_ids
           }) do
      render(conn, :show, chain: chain)
    end
  end

  defp current_user(conn), do: Api.Infrastructure.Guardian.Plug.current_resource(conn)
end
