defmodule Api.Usecases.Connection.ConnectPosts.ConnectPostsUsecaseDto do
  @moduledoc """
  Input for `Api.Usecases.Connection.ConnectPosts.ConnectPostsUsecase`.
  """

  alias Api.Infrastructure.Repository.User.Postgres.User

  @enforce_keys [:user, :post_id, :related_post_id, :relationship_type]
  defstruct [:user, :post_id, :related_post_id, :relationship_type]

  @type t :: %__MODULE__{
          user: %User{},
          post_id: Ecto.UUID.t(),
          related_post_id: Ecto.UUID.t(),
          relationship_type: String.t()
        }
end
