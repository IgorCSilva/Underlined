defmodule Api.Usecases.Wishlist.AddToWishlist.AddToWishlistUsecase do
  @moduledoc """
  Adds a book to a user's wishlist. Idempotent.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`. Unlike
  likes and follows, wishlisting has no Community Health pairing, so
  there's no event to enqueue here.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User
  alias Api.Usecases.Wishlist.AddToWishlist.AddToWishlistUsecaseDto

  defstruct [:repository]

  def call(%AddToWishlistUsecaseDto{user: %User{} = user, book_id: book_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.add_to_wishlist(user, book_id, adaptee)
  end
end
