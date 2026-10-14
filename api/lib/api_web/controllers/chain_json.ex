defmodule ApiWeb.ChainJSON do
  alias Api.Domain.Chain
  alias Api.Domain.ChainItem

  def index(%{chains: chains}), do: %{data: Enum.map(chains, &data/1)}
  def show(%{chain: chain}), do: %{data: data(chain)}

  def data(%Chain{} = chain) do
    %{
      id: chain.id,
      title: chain.title,
      inserted_at: chain.inserted_at,
      user: %{
        id: chain.user.id,
        name: chain.user.name,
        avatar_url: chain.user.avatar_url
      },
      items: Enum.map(chain.items, &item_data/1)
    }
  end

  defp item_data(%ChainItem{} = item) do
    %{
      id: item.id,
      position: item.position,
      post: ApiWeb.PostJSON.data(item.post)
    }
  end
end
