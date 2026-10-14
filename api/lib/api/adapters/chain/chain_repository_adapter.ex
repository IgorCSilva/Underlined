defmodule Api.Adapters.Chain.ChainRepositoryAdapter do
  @moduledoc """
  Adapts a chain repository (the adaptee) to the domain: calls it for the
  database entity/entities, then converts the result(s) into the pure
  Api.Domain.Chain/Api.Domain.ChainItem business entities.
  """

  alias Api.Adapters.Post.PostRepositoryAdapter
  alias Api.Adapters.User.UserRepositoryAdapter
  alias Api.Domain.Chain, as: DomainChain
  alias Api.Domain.ChainItem, as: DomainChainItem

  def create_chain(user, title, adaptee) do
    case adaptee.create_chain(user, title) do
      {:ok, db_chain} -> {:ok, to_domain(db_chain)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_chains(adaptee), do: adaptee.list_chains() |> Enum.map(&to_domain/1)

  def get_chain(id, adaptee) do
    case adaptee.get_chain(id) do
      {:error, :not_found} -> {:error, :not_found}
      {:ok, db_chain} -> {:ok, to_domain(db_chain)}
    end
  end

  def add_item(user, chain_id, post_id, adaptee) do
    case adaptee.add_item(user, chain_id, post_id) do
      {:error, :not_found} -> {:error, :not_found}
      {:error, :forbidden} -> {:error, :forbidden}
      {:error, changeset} -> {:error, changeset}
      {:ok, db_chain} -> {:ok, to_domain(db_chain)}
    end
  end

  def reorder_items(user, chain_id, item_ids, adaptee) do
    case adaptee.reorder_items(user, chain_id, item_ids) do
      {:error, :not_found} -> {:error, :not_found}
      {:error, :forbidden} -> {:error, :forbidden}
      {:error, :invalid_item_ids} -> {:error, :invalid_item_ids}
      {:ok, db_chain} -> {:ok, to_domain(db_chain)}
    end
  end

  defp to_domain(db_chain) do
    items =
      db_chain.items
      |> Enum.with_index()
      |> Enum.map(fn {db_item, position} -> item_to_domain(db_item, position) end)

    %DomainChain{
      id: db_chain.id,
      title: db_chain.title,
      user: UserRepositoryAdapter.to_domain(db_chain.user),
      items: items,
      inserted_at: db_chain.inserted_at
    }
  end

  defp item_to_domain(db_item, position) do
    %DomainChainItem{
      id: db_item.id,
      position: position,
      post: PostRepositoryAdapter.to_domain(db_item.post)
    }
  end
end
