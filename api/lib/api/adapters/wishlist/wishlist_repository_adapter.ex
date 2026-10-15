defmodule Api.Adapters.Wishlist.WishlistRepositoryAdapter do
  @moduledoc """
  Adapts a wishlist repository (the adaptee) to the usecase layer. The
  toggle actions pass the resulting wishlisted? state straight through;
  listing a wishlist converts each result into the pure
  Api.Domain.WishlistItem business entity, same as
  Api.Adapters.UserBook.UserBookRepositoryAdapter does for the bookcase.
  """

  alias Api.Adapters.Book.BookRepositoryAdapter
  alias Api.Domain.WishlistItem

  def add_to_wishlist(user, book_id, adaptee), do: adaptee.add_to_wishlist(user, book_id)

  def remove_from_wishlist(user, book_id, adaptee),
    do: adaptee.remove_from_wishlist(user, book_id)

  def list_wishlist(user_id, adaptee) do
    adaptee.list_wishlist(user_id) |> Enum.map(&to_domain/1)
  end

  @doc "Converts a Postgres wishlist entity (with :book preloaded) into the pure domain entity."
  def to_domain(db_wishlist_item) do
    %WishlistItem{
      id: db_wishlist_item.id,
      book: BookRepositoryAdapter.to_domain(db_wishlist_item.book),
      inserted_at: db_wishlist_item.inserted_at,
      updated_at: db_wishlist_item.updated_at
    }
  end
end
