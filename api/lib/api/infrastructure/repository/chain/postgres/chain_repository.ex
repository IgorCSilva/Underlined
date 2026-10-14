defmodule Api.Infrastructure.Repository.Chain.Postgres.ChainRepository do
  @moduledoc """
  Postgres-backed data access for the idea-chain entity. Order within a
  chain is modeled as a linked list (`previous_item_id`) rather than a
  renumbered position column, and walked with a recursive CTE — see
  technologies.md's rationale for not needing a graph database yet.
  """

  import Ecto.Query, warn: false

  alias Api.Infrastructure.Repository.Chain.Postgres.Chain
  alias Api.Infrastructure.Repository.Chain.Postgres.ChainItem
  alias Api.Infrastructure.Repository.Post.Postgres.PostRepository
  alias Api.Repo

  @post_preloads [:book, :passage, :keywords, :user]

  @doc "Creates an empty chain titled `title`, authored by `user`."
  def create_chain(user, title) do
    case %Chain{} |> Chain.changeset(%{"user_id" => user.id, "title" => title}) |> Repo.insert() do
      {:ok, chain} -> {:ok, %{chain | items: []} |> Repo.preload(:user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc "Every chain, newest first, each with its items in order."
  def list_chains do
    Chain
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.map(&with_ordered_items/1)
  end

  @doc "A single chain with its items in order. `{:error, :not_found}` if it doesn't exist."
  def get_chain(id) do
    case fetch_chain(id) do
      nil -> {:error, :not_found}
      chain -> {:ok, with_ordered_items(chain)}
    end
  end

  @doc """
  Appends `post_id` to the end of chain `chain_id`. Returns the whole
  chain, reordered. `{:error, :not_found}` if the chain or post doesn't
  exist, `{:error, :forbidden}` if `user` isn't the chain's author.
  """
  def add_item(user, chain_id, post_id) do
    case fetch_chain(chain_id) do
      nil ->
        {:error, :not_found}

      %Chain{} = chain ->
        cond do
          chain.user_id != user.id ->
            {:error, :forbidden}

          is_nil(PostRepository.fetch_post(post_id)) ->
            {:error, :not_found}

          true ->
            last = chain |> ordered_items() |> List.last()

            attrs = %{
              "chain_id" => chain_id,
              "post_id" => post_id,
              "previous_item_id" => last && last.id
            }

            case %ChainItem{} |> ChainItem.changeset(attrs) |> Repo.insert() do
              {:ok, _item} -> get_chain(chain_id)
              {:error, changeset} -> {:error, changeset}
            end
        end
    end
  end

  @doc """
  Reorders chain `chain_id`'s items to match `item_ids` (every existing
  item id, in the new order). `{:error, :invalid_item_ids}` if the set
  doesn't exactly match the chain's current items. `{:error, :forbidden}`
  if `user` isn't the chain's author.
  """
  def reorder_items(user, chain_id, item_ids) do
    case fetch_chain(chain_id) do
      nil ->
        {:error, :not_found}

      %Chain{} = chain ->
        existing_ids = chain |> ordered_items() |> Enum.map(& &1.id)

        cond do
          chain.user_id != user.id ->
            {:error, :forbidden}

          not same_members?(item_ids, existing_ids) ->
            {:error, :invalid_item_ids}

          true ->
            # previous_item_id's unique constraint is DEFERRABLE INITIALLY
            # DEFERRED precisely so this per-row re-pointing (which can pass
            # through states where two rows briefly share a soon-to-be-stale
            # value) only gets checked once, against the final state, at
            # commit — see the migration's comment.
            Repo.transaction(fn ->
              item_ids
              |> Enum.with_index()
              |> Enum.each(fn {item_id, index} ->
                previous_id = if index == 0, do: nil, else: Enum.at(item_ids, index - 1)

                Repo.get!(ChainItem, item_id)
                |> Ecto.Changeset.change(previous_item_id: previous_id)
                |> Repo.update!()
              end)
            end)

            get_chain(chain_id)
        end
    end
  end

  defp same_members?(a, b), do: length(a) == length(b) and MapSet.new(a) == MapSet.new(b)

  defp fetch_chain(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} -> Repo.get(Chain, uuid) |> maybe_preload_user()
      :error -> nil
    end
  end

  defp maybe_preload_user(nil), do: nil
  defp maybe_preload_user(chain), do: Repo.preload(chain, :user)

  defp with_ordered_items(chain), do: %{chain | items: ordered_items(chain)}

  defp ordered_items(%Chain{id: chain_id}) do
    base =
      from i in ChainItem,
        where: i.chain_id == ^chain_id and is_nil(i.previous_item_id),
        select: %{id: i.id, position: 0}

    recursive =
      from i in ChainItem,
        join: w in "chain_walk",
        on: i.previous_item_id == w.id,
        select: %{id: i.id, position: w.position + 1}

    walk = base |> union_all(^recursive)

    positions =
      ChainItem
      |> recursive_ctes(true)
      |> with_cte("chain_walk", as: ^walk)
      |> join(:inner, [i], w in "chain_walk", on: i.id == w.id)
      |> select([i, w], {i.id, w.position})
      |> Repo.all()

    position_by_id = Map.new(positions)
    ids = Map.keys(position_by_id)

    ChainItem
    |> where([i], i.id in ^ids)
    |> Repo.all()
    |> Repo.preload(post: @post_preloads)
    |> Enum.sort_by(&Map.fetch!(position_by_id, &1.id))
  end
end
