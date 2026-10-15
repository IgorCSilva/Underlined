defmodule ApiWeb.WishlistJSON do
  alias Api.Domain.WishlistItem
  alias ApiWeb.BookJSON

  def show(%{wishlist_item: wishlist_item}), do: %{data: wishlist_item}

  def index(%{wishlist: wishlist}), do: %{data: Enum.map(wishlist, &data/1)}

  defp data(%WishlistItem{} = item) do
    %{id: item.id, book: BookJSON.data(item.book)}
  end
end
