defmodule Api.Usecases.Wishlist.ListWishlist.ListWishlistUsecase do
  @moduledoc """
  Every book on a user's wishlist, most recently wishlisted first.

  Knows nothing about adapters or infrastructure: the caller injects a
  `repository` of shape `%{adapter: adapter, adaptee: adaptee}`.
  """

  alias Api.Usecases.Wishlist.ListWishlist.ListWishlistUsecaseDto

  defstruct [:repository]

  def call(%ListWishlistUsecaseDto{user_id: user_id}, %__MODULE__{
        repository: %{adapter: adapter, adaptee: adaptee}
      }) do
    adapter.list_wishlist(user_id, adaptee)
  end
end
