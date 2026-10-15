defmodule Api.Usecases.Wishlist.RemoveFromWishlist.RemoveFromWishlistUsecase do
  @moduledoc """
  Removes a book from a user's wishlist. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`. Unlike
  likes and follows, wishlisting has no Community Health pairing, so
  there's no event to enqueue here.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Wishlist.RemoveFromWishlist.RemoveFromWishlistUsecaseDto

  defstruct [:repository]

  def call(%RemoveFromWishlistUsecaseDto{user: %User{} = user, book_id: book_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.remove_from_wishlist(user, book_id, adaptee)
  end
end
